#!/usr/bin/env python3
"""
Kapadokya NetBoot - Web UI
Version: 1.0 MVP
"""

from flask import Flask, render_template, jsonify, request, redirect, url_for, flash, Blueprint, send_from_directory
from werkzeug.utils import secure_filename
import yaml
import json
import os
import subprocess
import re
from pathlib import Path
from datetime import datetime

app = Flask(__name__)
app.config['SECRET_KEY'] = 'kapadokya-netboot-secret-change-me'
app.config['MAX_CONTENT_LENGTH'] = 10 * 1024 * 1024  # 10MB max upload size
app.config['ALLOWED_BOOT_EXTENSIONS'] = {'kpxe', 'efi', 'pxe', '0', 'bin'}

# Middleware to handle X-Forwarded-Prefix from NGINX
class PrefixMiddleware(object):
    def __init__(self, app, prefix=''):
        self.app = app
        self.prefix = prefix

    def __call__(self, environ, start_response):
        # Get prefix from X-Forwarded-Prefix header or use default
        prefix = environ.get('HTTP_X_FORWARDED_PREFIX', self.prefix)
        if prefix:
            environ['SCRIPT_NAME'] = prefix
            # Fix PATH_INFO to remove prefix if it's there
            path_info = environ.get('PATH_INFO', '')
            if path_info.startswith(prefix):
                environ['PATH_INFO'] = path_info[len(prefix):]
        return self.app(environ, start_response)

app.wsgi_app = PrefixMiddleware(app.wsgi_app, prefix='/admin')

# Paths
BASE_DIR = Path('/opt/knetboot')
CONFIG_DIR = BASE_DIR / 'config'
ASSETS_DIR = BASE_DIR / 'assets'
IMAGES_YAML = CONFIG_DIR / 'images.yaml'
SETTINGS_YAML = CONFIG_DIR / 'settings.yaml'
SYSTEM_CONFIG_JSON = CONFIG_DIR / 'system.json'
DHCP_CONFIG_PATH = '/etc/dhcp/dhcpd.conf'
DHCP_SERVICE = 'isc-dhcp-server'
TFTP_CONFIG_PATH = '/etc/default/tftpd-hpa'
TFTP_SERVICE = 'tftpd-hpa'
TFTP_ROOT = '/srv/tftp'
NGINX_SERVICE = 'nginx'

def load_images():
    """Load images from YAML"""
    if not IMAGES_YAML.exists():
        return []
    with open(IMAGES_YAML) as f:
        data = yaml.safe_load(f)
        return data.get('images', [])

def save_images(images):
    """Save images to YAML"""
    with open(IMAGES_YAML, 'w') as f:
        yaml.dump({'images': images}, f, default_flow_style=False)

def load_system_config():
    """Load system configuration from JSON"""
    if not SYSTEM_CONFIG_JSON.exists():
        # Return default config if file doesn't exist
        return {
            'server': {'ip': '192.168.122.20', 'name': 'knetboot-server'},
            'network': {
                'subnet': '192.168.122.0',
                'netmask': '255.255.255.0',
                'gateway': '192.168.122.1',
                'dns': '192.168.122.1, 8.8.8.8',
                'dhcp_start': '192.168.122.100',
                'dhcp_end': '192.168.122.200',
                'next_server': '192.168.122.20'
            }
        }
    try:
        with open(SYSTEM_CONFIG_JSON, 'r') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading system config: {e}")
        return {}

def save_system_config(config):
    """Save system configuration to JSON"""
    try:
        config['last_updated'] = datetime.utcnow().isoformat() + 'Z'
        with open(SYSTEM_CONFIG_JSON, 'w') as f:
            json.dump(config, f, indent=2)
        return True
    except Exception as e:
        print(f"Error saving system config: {e}")
        return False

def load_settings():
    """Load settings from system config (for backward compatibility)"""
    system_config = load_system_config()
    return system_config

def get_disk_usage():
    """Get disk usage using df -h for root filesystem"""
    try:
        # Get disk usage of root filesystem (where everything is stored)
        result = subprocess.run(
            ['df', '-h', '/'],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            lines = result.stdout.strip().split('\n')
            if len(lines) > 1:
                # Parse output: Filesystem Size Used Avail Use% Mounted
                parts = lines[1].split()
                if len(parts) >= 5:
                    size = parts[1]      # e.g., "100G"
                    used = parts[2]      # e.g., "45G"
                    avail = parts[3]     # e.g., "55G"
                    percent = parts[4]   # e.g., "45%"

                    # Convert to float (handle G, M, T suffixes)
                    def parse_size(s):
                        s = s.upper()
                        if 'T' in s:
                            return float(s.replace('T', '')) * 1024
                        elif 'G' in s:
                            return float(s.replace('G', ''))
                        elif 'M' in s:
                            return float(s.replace('M', '')) / 1024
                        else:
                            return 0

                    return {
                        'size': size,
                        'used': used,
                        'available': avail,
                        'percent': percent,
                        'used_gb': parse_size(used),
                        'total_gb': parse_size(size)
                    }
        return {
            'size': 'Unknown',
            'used': 'Unknown',
            'available': 'Unknown',
            'percent': '0%',
            'used_gb': 0,
            'total_gb': 100
        }
    except Exception as e:
        print(f"Error getting disk usage: {e}")
        return {
            'size': 'Unknown',
            'used': 'Unknown',
            'available': 'Unknown',
            'percent': '0%',
            'used_gb': 0,
            'total_gb': 100
        }

def get_service_status(service):
    """Check if systemd service is active"""
    try:
        result = subprocess.run(
            ['/usr/bin/sudo', '/usr/bin/systemctl', 'is-active', service],
            capture_output=True,
            text=True
        )
        return result.stdout.strip() == 'active'
    except:
        return False

def parse_dhcp_config():
    """Parse current DHCP configuration"""
    config = {
        'network': '192.168.122.0',
        'netmask': '255.255.255.0',
        'range_start': '192.168.122.100',
        'range_end': '192.168.122.200',
        'gateway': '192.168.122.1',
        'dns': '192.168.122.1, 8.8.8.8',
        'next_server': '192.168.122.20'
    }

    try:
        with open(DHCP_CONFIG_PATH, 'r') as f:
            content = f.read()

        # Parse subnet
        subnet_match = re.search(r'subnet\s+([\d.]+)\s+netmask\s+([\d.]+)', content)
        if subnet_match:
            config['network'] = subnet_match.group(1)
            config['netmask'] = subnet_match.group(2)

        # Parse range
        range_match = re.search(r'range\s+([\d.]+)\s+([\d.]+)', content)
        if range_match:
            config['range_start'] = range_match.group(1)
            config['range_end'] = range_match.group(2)

        # Parse gateway
        gateway_match = re.search(r'option routers\s+([\d.]+)', content)
        if gateway_match:
            config['gateway'] = gateway_match.group(1)

        # Parse DNS
        dns_match = re.search(r'option domain-name-servers\s+([^;]+)', content)
        if dns_match:
            config['dns'] = dns_match.group(1).strip()

        # Parse next-server
        next_match = re.search(r'next-server\s+([\d.]+)', content)
        if next_match:
            config['next_server'] = next_match.group(1)

    except Exception as e:
        print(f"Error parsing DHCP config: {e}")

    return config

def calculate_broadcast(network, netmask):
    """Calculate broadcast address"""
    try:
        net_parts = [int(x) for x in network.split('.')]
        mask_parts = [int(x) for x in netmask.split('.')]
        broadcast = [str(net_parts[i] | (~mask_parts[i] & 255)) for i in range(4)]
        return '.'.join(broadcast)
    except:
        return '192.168.122.255'

def write_dhcp_config(config):
    """Write new DHCP configuration"""
    dhcp_config = f"""# Kapadokya NetBoot DHCP Configuration
authoritative;
default-lease-time 600;
max-lease-time 7200;
ddns-update-style none;

# Define PXE options
option space PXE;
option PXE.mtftp-ip code 1 = ip-address;

subnet {config['network']} netmask {config['netmask']} {{
    range {config['range_start']} {config['range_end']};
    option routers {config['gateway']};
    option domain-name-servers {config['dns']};
    option domain-name "knetboot.local";
    option broadcast-address {calculate_broadcast(config['network'], config['netmask'])};

    next-server {config['next_server']};

    # iPXE already loaded - chain to HTTP menu
    if exists user-class and option user-class = "iPXE" {{
        filename "http://{config['next_server']}/knetboot/boot.ipxe";
    }}
    # UEFI x64 (Client System Architecture Type 7 or 9)
    elsif substring(option vendor-class-identifier, 0, 20) = "PXEClient:Arch:00007" or
         substring(option vendor-class-identifier, 0, 20) = "PXEClient:Arch:00009" {{
        filename "ipxe.efi";
    }}
    # BIOS/Legacy
    else {{
        filename "undionly.kpxe";
    }}
}}
"""

    try:
        # Write config using sudo tee
        process = subprocess.Popen(['/usr/bin/sudo', '/usr/bin/tee', DHCP_CONFIG_PATH],
                                 stdin=subprocess.PIPE,
                                 stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE,
                                 text=True)
        stdout, stderr = process.communicate(input=dhcp_config)

        if process.returncode == 0:
            # Test config syntax
            test_result = subprocess.run(['/usr/bin/sudo', '/usr/sbin/dhcpd', '-t', '-cf', DHCP_CONFIG_PATH],
                                       capture_output=True, text=True)
            if test_result.returncode == 0:
                return True, "Configuration updated successfully!"
            else:
                return False, f"Config syntax error: {test_result.stderr}"
        else:
            return False, f"Failed to write config: {stderr}"

    except Exception as e:
        return False, f"Error writing config: {str(e)}"

def get_boot_statistics():
    """
    Parse DHCP leases and TFTP logs to get boot statistics
    Returns: dict with boot stats
    """
    stats = {
        'total_boots_today': 0,
        'successful_boots': 0,
        'failed_boots': 0,
        'active_leases': 0,
        'success_rate': 0,
        'most_used_image': 'N/A'
    }

    try:
        # Parse DHCP leases for active clients
        dhcp_leases_path = '/var/lib/dhcp/dhcpd.leases'
        if os.path.exists(dhcp_leases_path):
            result = subprocess.run(
                ['sudo', 'cat', dhcp_leases_path],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0:
                # Count active leases (simple count of "lease" entries)
                stats['active_leases'] = result.stdout.count('lease ')

        # Parse TFTP logs for boot attempts (last 24 hours)
        tftp_log_result = subprocess.run(
            ['sudo', 'journalctl', '-u', 'tftpd-hpa', '--since', 'today', '--no-pager'],
            capture_output=True,
            text=True,
            timeout=10
        )

        if tftp_log_result.returncode == 0:
            log_lines = tftp_log_result.stdout.split('\n')

            # Count RRQ (Read Request) as boot attempts
            boot_attempts = [line for line in log_lines if 'RRQ' in line or 'sent' in line.lower()]
            stats['total_boots_today'] = len(boot_attempts)

            # Count successful transfers (files sent successfully)
            successful = [line for line in log_lines if 'sent' in line.lower() and ('kpxe' in line.lower() or 'efi' in line.lower())]
            stats['successful_boots'] = len(successful)

            # Calculate failed boots
            stats['failed_boots'] = max(0, stats['total_boots_today'] - stats['successful_boots'])

            # Calculate success rate
            if stats['total_boots_today'] > 0:
                stats['success_rate'] = int((stats['successful_boots'] / stats['total_boots_today']) * 100)
            else:
                stats['success_rate'] = 0

            # Find most requested file (most used image)
            file_requests = {}
            for line in log_lines:
                if 'RRQ' in line:
                    # Extract filename from log
                    match = re.search(r'RRQ.*?([a-zA-Z0-9_\-\.]+\.(kpxe|efi|ipxe))', line)
                    if match:
                        filename = match.group(1)
                        file_requests[filename] = file_requests.get(filename, 0) + 1

            if file_requests:
                most_used = max(file_requests, key=file_requests.get)
                stats['most_used_image'] = most_used

    except subprocess.TimeoutExpired:
        print("Timeout while fetching boot statistics")
    except Exception as e:
        print(f"Error getting boot statistics: {e}")

    return stats

def get_system_uptime():
    """Get system uptime in human-readable format"""
    try:
        result = subprocess.run(
            ['uptime', '-p'],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            # Remove "up " prefix
            uptime = result.stdout.strip().replace('up ', '')
            return uptime
        return "Unknown"
    except:
        return "Unknown"

@app.route('/')
def index():
    """Dashboard"""
    images = load_images()
    settings = load_settings()

    # Get boot statistics from logs
    boot_stats = get_boot_statistics()
    uptime = get_system_uptime()

    stats = {
        'total_images': len(images),
        'enabled_images': len([i for i in images if i.get('enabled', False)]),
        'disk_usage': get_disk_usage(),
        'services': {
            'dhcp': get_service_status('isc-dhcp-server'),
            'tftp': get_service_status('tftpd-hpa'),
            'nginx': get_service_status('nginx'),
            'web': get_service_status('knetboot-web')
        },
        # Boot statistics
        'boots_today': boot_stats['total_boots_today'],
        'successful_boots': boot_stats['successful_boots'],
        'failed_boots': boot_stats['failed_boots'],
        'boot_success_rate': boot_stats['success_rate'],
        'active_clients': boot_stats['active_leases'],
        'most_used_image': boot_stats['most_used_image'],
        'uptime': uptime
    }

    return render_template('dashboard.html', stats=stats, settings=settings)

@app.route('/images')
def images_list():
    """Image list page"""
    images = load_images()
    return render_template('images.html', images=images)

@app.route('/settings')
def settings_page():
    """Settings page"""
    settings = load_system_config()

    # Get real hostname from hostnamectl
    try:
        result = subprocess.run(['/usr/bin/hostnamectl', 'hostname'],
                              capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            settings['server']['name'] = result.stdout.strip()
    except Exception as e:
        print(f"Error getting hostname: {e}")

    return render_template('settings.html', settings=settings)

@app.route('/settings/time', methods=['POST'])
def update_time_settings():
    """Update timezone and NTP settings"""
    try:
        timezone = request.form.get('timezone', 'UTC')
        ntp_server = request.form.get('ntp_server', '')
        ntp_fallback = request.form.get('ntp_fallback', '')

        # Update system.json
        system_config = load_system_config()
        system_config['server']['timezone'] = timezone
        system_config['server']['ntp_server'] = ntp_server
        system_config['server']['ntp_fallback'] = ntp_fallback
        save_system_config(system_config)

        # Apply timezone change
        if timezone:
            result = subprocess.run(['/usr/bin/sudo', '/usr/bin/timedatectl', 'set-timezone', timezone],
                                  capture_output=True, text=True, timeout=10)
            if result.returncode != 0:
                flash(f'Warning: Could not set timezone: {result.stderr}', 'warning')

        # Update NTP configuration
        if ntp_server:
            ntp_config = f"[Time]\nNTP={ntp_server}\n"
            if ntp_fallback:
                ntp_config += f"FallbackNTP={ntp_fallback}\n"

            # Write NTP config
            process = subprocess.Popen(['/usr/bin/sudo', '/usr/bin/tee', '/etc/systemd/timesyncd.conf.d/local.conf'],
                                     stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            stdout, stderr = process.communicate(input=ntp_config)

            if process.returncode == 0:
                # Restart NTP service
                subprocess.run(['/usr/bin/sudo', '/usr/bin/systemctl', 'restart', 'systemd-timesyncd'],
                             capture_output=True, text=True, timeout=10)
                flash('Time settings updated successfully!', 'success')
            else:
                flash(f'Error updating NTP config: {stderr}', 'danger')
        else:
            flash('Settings saved to system.json', 'success')

    except Exception as e:
        flash(f'Error updating time settings: {str(e)}', 'danger')

    return redirect(url_for('settings_page'))

@app.route('/settings/dns', methods=['POST'])
def update_dns_settings():
    """Update DNS settings"""
    try:
        dns_primary = request.form.get('dns_primary', '')
        dns_secondary = request.form.get('dns_secondary', '')
        dns_tertiary = request.form.get('dns_tertiary', '')

        # Validate DNS IPs
        from ipaddress import IPv4Address
        try:
            if dns_primary:
                IPv4Address(dns_primary)
            if dns_secondary:
                IPv4Address(dns_secondary)
            if dns_tertiary:
                IPv4Address(dns_tertiary)
        except ValueError as e:
            flash(f'Error: Invalid IP address format - {str(e)}', 'danger')
            return redirect(url_for('settings_page'))

        # Update system.json
        system_config = load_system_config()

        # Build DNS servers list
        dns_servers = []
        if dns_primary:
            dns_servers.append(dns_primary)
        if dns_secondary:
            dns_servers.append(dns_secondary)
        if dns_tertiary:
            dns_servers.append(dns_tertiary)

        system_config['network']['dns_servers'] = dns_servers
        system_config['network']['dns_primary'] = dns_primary
        system_config['network']['dns_secondary'] = dns_secondary
        system_config['network']['dns'] = ', '.join(dns_servers)

        if save_system_config(system_config):
            flash('DNS settings updated successfully in system.json', 'success')
            flash('Note: DNS changes will be applied to DHCP clients on next lease. Update DHCP config to apply now.', 'info')
        else:
            flash('Warning: Failed to save system.json', 'warning')

    except Exception as e:
        flash(f'Error updating DNS settings: {str(e)}', 'danger')

    return redirect(url_for('settings_page'))

@app.route('/menus')
def menus_page():
    """Menus page"""
    menus_dir = CONFIG_DIR / 'menus'
    menu_files = []
    if menus_dir.exists():
        menu_files = [f.name for f in menus_dir.glob('*.ipxe')]
    return render_template('menus.html', menu_files=menu_files)

@app.route('/dhcp')
def dhcp_config_page():
    """DHCP Configuration page"""
    # Try to load from system.json first, fallback to parsing dhcpd.conf
    system_config = load_system_config()
    if 'network' in system_config:
        config = {
            'network': system_config['network'].get('subnet', '192.168.122.0'),
            'netmask': system_config['network'].get('netmask', '255.255.255.0'),
            'range_start': system_config['network'].get('dhcp_start', '192.168.122.100'),
            'range_end': system_config['network'].get('dhcp_end', '192.168.122.200'),
            'gateway': system_config['network'].get('gateway', '192.168.122.1'),
            'dns': system_config['network'].get('dns', '192.168.122.1, 8.8.8.8'),
            'next_server': system_config['network'].get('next_server', '192.168.122.20')
        }
    else:
        # Fallback to parsing dhcpd.conf
        config = parse_dhcp_config()

    dhcp_enabled = get_service_status(DHCP_SERVICE)
    return render_template('dhcp_config.html', config=config, dhcp_enabled=dhcp_enabled)

@app.route('/dhcp/update', methods=['POST'])
def dhcp_update():
    """Update DHCP configuration"""
    config = {
        'network': request.form.get('network'),
        'netmask': request.form.get('netmask'),
        'range_start': request.form.get('range_start'),
        'range_end': request.form.get('range_end'),
        'gateway': request.form.get('gateway'),
        'dns': request.form.get('dns'),
        'next_server': request.form.get('next_server')
    }

    # Validate DHCP range: end IP must be greater than start IP
    try:
        from ipaddress import IPv4Address
        start_ip = IPv4Address(config['range_start'])
        end_ip = IPv4Address(config['range_end'])

        if end_ip <= start_ip:
            flash(f'Error: DHCP Range End ({config["range_end"]}) must be greater than Range Start ({config["range_start"]})', 'danger')
            return redirect(url_for('dhcp_config_page'))
    except ValueError as e:
        flash(f'Error: Invalid IP address format - {str(e)}', 'danger')
        return redirect(url_for('dhcp_config_page'))

    success, message = write_dhcp_config(config)

    if success:
        # Update system.json with new DHCP config
        try:
            system_config = load_system_config()
            # Preserve existing network config, only update changed fields
            if 'network' not in system_config:
                system_config['network'] = {}

            system_config['network']['subnet'] = config['network']
            system_config['network']['netmask'] = config['netmask']
            system_config['network']['gateway'] = config['gateway']
            system_config['network']['dns'] = config['dns']
            system_config['network']['dhcp_start'] = config['range_start']
            system_config['network']['dhcp_end'] = config['range_end']
            system_config['network']['next_server'] = config['next_server']

            if save_system_config(system_config):
                print(f"DEBUG: system.json updated successfully with range {config['range_start']}-{config['range_end']}")
            else:
                print("DEBUG: Failed to save system.json")
                flash('Warning: DHCP config updated but system.json not saved', 'warning')
        except Exception as e:
            print(f"DEBUG: Exception updating system.json: {e}")
            flash(f'Warning: DHCP config updated but system.json error: {str(e)}', 'warning')

        flash(message, 'success')
    else:
        flash(message, 'danger')

    return redirect(url_for('dhcp_config_page'))

@app.route('/dhcp/restart')
def dhcp_restart():
    """Restart DHCP service"""
    try:
        result = subprocess.run(['/usr/bin/sudo', '/usr/bin/systemctl', 'restart', DHCP_SERVICE],
                              capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            flash('DHCP server restarted successfully!', 'success')
        else:
            flash(f'Failed to restart DHCP: {result.stderr}', 'danger')
    except Exception as e:
        flash(f'Error restarting DHCP: {str(e)}', 'danger')

    return redirect(url_for('dhcp_config_page'))

@app.route('/dhcp/toggle', methods=['POST'])
def dhcp_toggle():
    """Toggle DHCP service on/off"""
    try:
        data = request.get_json()
        enable = data.get('enable', False)

        action = 'start' if enable else 'stop'
        result = subprocess.run(['/usr/bin/sudo', '/usr/bin/systemctl', action, DHCP_SERVICE],
                              capture_output=True, text=True, timeout=10)

        if result.returncode == 0:
            status = 'started' if enable else 'stopped'
            return jsonify({
                'success': True,
                'message': f'DHCP server {status} successfully!',
                'enabled': enable
            })
        else:
            return jsonify({
                'success': False,
                'error': result.stderr
            }), 500
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

# TFTP Configuration Routes

@app.route('/tftp')
def tftp_config_page():
    """TFTP Configuration page"""
    # Load TFTP config
    config = {
        'tftp_root': TFTP_ROOT,
        'tftp_address': '0.0.0.0',
        'tftp_options': '--secure'
    }

    # Try to parse /etc/default/tftpd-hpa
    try:
        if Path(TFTP_CONFIG_PATH).exists():
            with open(TFTP_CONFIG_PATH, 'r') as f:
                content = f.read()
                # Parse TFTP_DIRECTORY
                dir_match = re.search(r'TFTP_DIRECTORY="([^"]+)"', content)
                if dir_match:
                    config['tftp_root'] = dir_match.group(1)
                # Parse TFTP_ADDRESS (remove :69 port if present)
                addr_match = re.search(r'TFTP_ADDRESS="([^"]+)"', content)
                if addr_match:
                    addr = addr_match.group(1)
                    # Remove port if present (e.g., "0.0.0.0:69" -> "0.0.0.0", ":69" -> "0.0.0.0")
                    if ':' in addr:
                        addr = addr.split(':')[0]
                        if not addr:  # Handle ":69" case
                            addr = '0.0.0.0'
                    config['tftp_address'] = addr
                # Parse TFTP_OPTIONS
                opt_match = re.search(r'TFTP_OPTIONS="([^"]+)"', content)
                if opt_match:
                    config['tftp_options'] = opt_match.group(1)
    except Exception as e:
        print(f"Error parsing TFTP config: {e}")

    # Get list of boot files
    boot_files = []
    try:
        tftp_dir = Path(config['tftp_root'])
        if tftp_dir.exists():
            for file in tftp_dir.iterdir():
                if file.is_file():
                    size_bytes = file.stat().st_size
                    size_str = f"{size_bytes / 1024:.1f} KB" if size_bytes < 1024*1024 else f"{size_bytes / (1024*1024):.1f} MB"

                    # Determine file type
                    file_type = 'other'
                    if '.kpxe' in file.name or 'undionly' in file.name:
                        file_type = 'bios'
                    elif '.efi' in file.name:
                        file_type = 'uefi'

                    boot_files.append({
                        'name': file.name,
                        'size': size_str,
                        'type': file_type
                    })
    except Exception as e:
        print(f"Error listing boot files: {e}")

    tftp_enabled = get_service_status(TFTP_SERVICE)
    return render_template('tftp_config.html', config=config, boot_files=boot_files, tftp_enabled=tftp_enabled)

@app.route('/tftp/update', methods=['POST'])
def tftp_update():
    """Update TFTP configuration"""
    try:
        tftp_root = request.form.get('tftp_root', TFTP_ROOT)
        tftp_address = request.form.get('tftp_address', '0.0.0.0')
        tftp_options = request.form.get('tftp_options', '--secure')

        # Ensure address has port (if not already specified)
        if ':' not in tftp_address:
            tftp_address = f"{tftp_address}:69"

        # Create new TFTP config
        tftp_config = f'''# /etc/default/tftpd-hpa
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="{tftp_root}"
TFTP_ADDRESS="{tftp_address}"
TFTP_OPTIONS="{tftp_options}"
'''

        # Write config using sudo tee
        process = subprocess.Popen(['/usr/bin/sudo', '/usr/bin/tee', TFTP_CONFIG_PATH],
                                 stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        stdout, stderr = process.communicate(input=tftp_config)

        if process.returncode == 0:
            flash('TFTP configuration updated successfully! Restart TFTP service to apply changes.', 'success')
        else:
            flash(f'Error writing TFTP config: {stderr}', 'danger')

    except Exception as e:
        flash(f'Error updating TFTP config: {str(e)}', 'danger')

    return redirect(url_for('tftp_config_page'))

@app.route('/tftp/restart')
def tftp_restart():
    """Restart TFTP service"""
    try:
        result = subprocess.run(['/usr/bin/sudo', '/usr/bin/systemctl', 'restart', TFTP_SERVICE],
                              capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            flash('TFTP server restarted successfully!', 'success')
        else:
            flash(f'Failed to restart TFTP: {result.stderr}', 'danger')
    except Exception as e:
        flash(f'Error restarting TFTP: {str(e)}', 'danger')

    return redirect(url_for('tftp_config_page'))

@app.route('/tftp/toggle', methods=['POST'])
def tftp_toggle():
    """Toggle TFTP service on/off"""
    try:
        data = request.get_json()
        enable = data.get('enable', False)

        action = 'start' if enable else 'stop'
        result = subprocess.run(['/usr/bin/sudo', '/usr/bin/systemctl', action, TFTP_SERVICE],
                              capture_output=True, text=True, timeout=10)

        if result.returncode == 0:
            status = 'started' if enable else 'stopped'
            return jsonify({
                'success': True,
                'message': f'TFTP server {status} successfully!',
                'enabled': enable
            })
        else:
            return jsonify({
                'success': False,
                'error': result.stderr
            }), 500
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/nginx/restart', methods=['POST'])
def nginx_restart():
    """Restart NGINX service"""
    try:
        result = subprocess.run(['/usr/bin/sudo', '/usr/bin/systemctl', 'restart', NGINX_SERVICE],
                              capture_output=True, text=True, timeout=10)

        if result.returncode == 0:
            return jsonify({
                'success': True,
                'message': 'NGINX server restarted successfully!'
            })
        else:
            return jsonify({
                'success': False,
                'error': result.stderr
            }), 500
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

def allowed_boot_file(filename):
    """Check if the uploaded file has an allowed extension"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in app.config['ALLOWED_BOOT_EXTENSIONS']

@app.route('/tftp/upload', methods=['POST'])
def tftp_upload():
    """Upload boot file to TFTP directory"""
    try:
        # Check if file was uploaded
        if 'boot_file' not in request.files:
            flash('No file selected', 'danger')
            return redirect(url_for('tftp_config_page'))

        file = request.files['boot_file']

        # Check if filename is empty
        if file.filename == '':
            flash('No file selected', 'danger')
            return redirect(url_for('tftp_config_page'))

        # Check file extension
        if not allowed_boot_file(file.filename):
            flash(f'Invalid file type. Allowed extensions: {", ".join(app.config["ALLOWED_BOOT_EXTENSIONS"])}', 'danger')
            return redirect(url_for('tftp_config_page'))

        # Secure the filename
        filename = secure_filename(file.filename)

        # Save to temporary location first
        temp_path = f"/tmp/{filename}"
        file.save(temp_path)

        # Move to TFTP directory with sudo (requires proper permissions)
        tftp_path = f"{TFTP_ROOT}/{filename}"
        result = subprocess.run(['/usr/bin/sudo', '/usr/bin/cp', temp_path, tftp_path],
                              capture_output=True, text=True, timeout=10)

        # Clean up temp file
        os.remove(temp_path)

        if result.returncode == 0:
            # Set proper permissions (readable by all)
            subprocess.run(['/usr/bin/sudo', '/usr/bin/chmod', '644', tftp_path],
                         capture_output=True, text=True, timeout=5)
            flash(f'File "{filename}" uploaded successfully to {TFTP_ROOT}', 'success')
        else:
            flash(f'Error uploading file: {result.stderr}', 'danger')

    except Exception as e:
        flash(f'Error uploading file: {str(e)}', 'danger')

    return redirect(url_for('tftp_config_page'))

@app.route('/tftp/delete/<filename>', methods=['POST'])
def tftp_delete_file(filename):
    """Delete a boot file from TFTP directory"""
    try:
        # Secure the filename
        filename = secure_filename(filename)
        tftp_path = f"{TFTP_ROOT}/{filename}"

        # Delete file with sudo
        result = subprocess.run(['/usr/bin/sudo', '/usr/bin/rm', '-f', tftp_path],
                              capture_output=True, text=True, timeout=10)

        if result.returncode == 0:
            flash(f'File "{filename}" deleted successfully', 'success')
        else:
            flash(f'Error deleting file: {result.stderr}', 'danger')

    except Exception as e:
        flash(f'Error deleting file: {str(e)}', 'danger')

    return redirect(url_for('tftp_config_page'))

@app.route('/boot/http/<path:filename>')
def serve_boot_file(filename):
    """Serve boot files over HTTP (alternative to TFTP)"""
    try:
        return send_from_directory(TFTP_ROOT, filename)
    except Exception as e:
        return f"Error: {str(e)}", 404

# API Endpoints

@app.route('/api/images', methods=['GET'])
def api_images_list():
    """API: Get all images"""
    images = load_images()
    return jsonify({'success': True, 'images': images})

@app.route('/api/images/<image_id>', methods=['GET'])
def api_image_get(image_id):
    """API: Get single image"""
    images = load_images()
    image = next((i for i in images if i['id'] == image_id), None)
    if image:
        return jsonify({'success': True, 'image': image})
    return jsonify({'success': False, 'error': 'Image not found'}), 404

@app.route('/api/images/<image_id>/toggle', methods=['POST'])
def api_image_toggle(image_id):
    """API: Toggle image enabled status"""
    images = load_images()
    image = next((i for i in images if i['id'] == image_id), None)
    if image:
        image['enabled'] = not image.get('enabled', False)
        save_images(images)
        return jsonify({'success': True, 'enabled': image['enabled']})
    return jsonify({'success': False, 'error': 'Image not found'}), 404

@app.route('/api/images/<image_id>', methods=['DELETE'])
def api_image_delete(image_id):
    """API: Delete image"""
    images = load_images()
    images = [i for i in images if i['id'] != image_id]
    save_images(images)
    return jsonify({'success': True})

@app.route('/api/menus/regenerate', methods=['POST'])
def api_menus_regenerate():
    """API: Regenerate iPXE menus"""
    try:
        script_path = BASE_DIR / 'scripts' / 'menu-generator.py'
        result = subprocess.run(
            ['python3', str(script_path)],
            capture_output=True,
            text=True,
            cwd=str(BASE_DIR)
        )
        if result.returncode == 0:
            return jsonify({'success': True, 'output': result.stdout})
        return jsonify({
            'success': False,
            'error': result.stderr
        }), 500
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/system/status', methods=['GET'])
def api_system_status():
    """API: Get system status"""
    return jsonify({
        'success': True,
        'services': {
            'dhcp': get_service_status('isc-dhcp-server'),
            'tftp': get_service_status('tftpd-hpa'),
            'nginx': get_service_status('nginx'),
            'web': get_service_status('knetboot-web')
        },
        'disk_usage': get_disk_usage()
    })

if __name__ == '__main__':
    # Development server
    app.run(host='0.0.0.0', port=5000, debug=True)
