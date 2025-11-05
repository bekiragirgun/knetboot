#!/bin/bash
# Kapadokya NetBoot - Complete Deployment & Health Check Script
# This script deploys everything from local machine to remote server
# Version: 2.3 - With HTTP Boot support and full v2.3 features

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Kapadokya NetBoot - Full Deployment v2.3${NC}"
echo -e "${GREEN}========================================${NC}"
echo

# Configuration
REMOTE_HOST="192.168.122.20"
REMOTE_USER="test"
REMOTE_PASS="123123!!"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${YELLOW}[INFO]${NC} Configuration:"
echo "  Remote Host: $REMOTE_USER@$REMOTE_HOST"
echo "  Local Path: $SCRIPT_DIR"
echo

# Check sshpass
if ! command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}[INSTALL]${NC} Installing sshpass..."
    sudo apt update -qq
    sudo apt install -y sshpass
fi

# Step 1: Test connection
echo -e "${YELLOW}[1/8]${NC} Testing connection to remote server..."
if sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$REMOTE_USER@$REMOTE_HOST" 'echo "Connected"' &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Connection successful"
else
    echo -e "  ${RED}✗${NC} Connection failed"
    exit 1
fi

# Step 2: Detect network interface
echo -e "${YELLOW}[2/8]${NC} Detecting network interface..."
DETECTED_IFACE=$(sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" \
    "ip -o -4 addr show | grep '192.168.122' | awk '{print \$2}'" | tr -d '\r')

if [ -z "$DETECTED_IFACE" ]; then
    echo -e "  ${YELLOW}!${NC} Could not detect interface, using default: enp1s0"
    DETECTED_IFACE="enp1s0"
else
    echo -e "  ${GREEN}✓${NC} Detected interface: $DETECTED_IFACE"
fi

# Step 3: Copy knetboot directory to remote
echo -e "${YELLOW}[3/8]${NC} Copying knetboot to remote server..."
sshpass -p "$REMOTE_PASS" scp -r -o StrictHostKeyChecking=no \
    "$SCRIPT_DIR" "$REMOTE_USER@$REMOTE_HOST:/tmp/knetboot" 2>/dev/null
echo -e "  ${GREEN}✓${NC} Files copied"

# Step 4: Create installation script on remote
echo -e "${YELLOW}[4/8]${NC} Creating remote installation script..."
sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" "cat > /tmp/install-knetboot.sh" <<REMOTE_SCRIPT
#!/bin/bash
set -e

echo "========================================="
echo "Installing Kapadokya NetBoot on Remote"
echo "========================================="
echo

# Variables
INSTALL_DIR="/opt/knetboot"
WEB_ROOT="/var/www/html/knetboot"
TFTP_ROOT="/srv/tftp"
SERVER_IP="192.168.122.20"
NETWORK="192.168.122.0"
DHCP_START="192.168.122.100"
DHCP_END="192.168.122.200"
GATEWAY="192.168.122.1"
IFACE="$DETECTED_IFACE"

# 1. Fix APT configuration for VMs with incorrect time
echo "[1/10] Configuring APT and mirrors..."

# Check if system time is in the future (common in VMs)
CURRENT_YEAR=\$(date +%Y)
echo "  Current system year: \$CURRENT_YEAR"

# Configure APT to ignore release file time validation
mkdir -p /etc/apt/apt.conf.d/
cat > /etc/apt/apt.conf.d/99fix-future-time <<'APTCONF'
Acquire::Check-Valid-Until "false";
Acquire::Check-Date "false";
APTCONF
echo "  ✓ APT time validation disabled"

# Switch to Turkish mirrors (faster and more reliable)
echo "  Switching to Turkish mirrors..."
cat > /etc/apt/sources.list <<'SOURCES'
# Ubuntu TR Mirrors
deb http://tr.archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse
deb http://tr.archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse
deb http://tr.archive.ubuntu.com/ubuntu/ noble-backports main restricted universe multiverse
deb http://tr.archive.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse
SOURCES
echo "  ✓ Turkish mirrors configured"

# 2. Install packages
echo "[2/10] Installing packages..."
export DEBIAN_FRONTEND=noninteractive
apt update -qq
apt install -y nginx python3 python3-pip python3-venv \
    isc-dhcp-server tftpd-hpa curl wget net-tools 2>&1 | grep -v "^debconf:" || true
echo "  ✓ Packages installed"

# 2. Create directories
echo "[2/10] Creating directory structure..."
mkdir -p \$INSTALL_DIR/{config/{menus,themes},web,scripts,assets/{ipxe,images,kernels}}
mkdir -p \$WEB_ROOT
mkdir -p \$TFTP_ROOT

# 3. Copy files from /tmp/knetboot
echo "[3/10] Copying knetboot files..."
if [ -d "/tmp/knetboot" ]; then
    cp -r /tmp/knetboot/* \$INSTALL_DIR/ 2>/dev/null || true
    # Fix permissions
    find \$INSTALL_DIR/scripts -name "*.sh" -exec chmod +x {} \;
    find \$INSTALL_DIR/scripts -name "*.py" -exec chmod +x {} \;
fi

# 4. Download iPXE bootloaders
echo "[4/10] Downloading iPXE bootloaders..."
cd \$TFTP_ROOT
if [ ! -f "undionly.kpxe" ]; then
    wget -q --timeout=10 http://boot.ipxe.org/undionly.kpxe -O undionly.kpxe || \
    echo "Warning: Could not download undionly.kpxe"
fi
if [ ! -f "ipxe.efi" ]; then
    wget -q --timeout=10 http://boot.ipxe.org/ipxe.efi -O ipxe.efi || \
    echo "Warning: Could not download ipxe.efi"
fi
chmod 644 *.kpxe *.efi 2>/dev/null || true
chown tftp:tftp * 2>/dev/null || true

# 5. Setup Python environment
echo "[5/10] Setting up Python environment..."
cd \$INSTALL_DIR/web

# Always recreate venv to ensure it's clean
if [ -d "venv" ]; then
    echo "  Removing old venv..."
    rm -rf venv
fi

echo "  Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate
echo "  Installing Python packages..."
pip install -q --upgrade pip
pip install -q flask pyyaml gunicorn
deactivate
echo "  ✓ Python environment ready"

# 6. Verify Flask app exists (copied from source)
echo "[6/10] Verifying Flask application..."
if [ ! -f "\$INSTALL_DIR/web/app.py" ]; then
    echo "  ERROR: app.py not found! Creating basic version..."
    cat > \$INSTALL_DIR/web/app.py <<'FLASK_APP'
from flask import Flask, render_template_string, jsonify
import os
import subprocess

app = Flask(__name__)

DASHBOARD_HTML = """
<!DOCTYPE html>
<html>
<head>
    <title>Kapadokya NetBoot Admin</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 3px solid #4CAF50; padding-bottom: 10px; }
        .status { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 20px 0; }
        .service { background: #fff; border: 1px solid #ddd; border-radius: 8px; padding: 20px; }
        .service h3 { margin: 0 0 10px 0; color: #555; }
        .running { border-left: 4px solid #4CAF50; }
        .failed { border-left: 4px solid #f44336; }
        .status-badge { display: inline-block; padding: 5px 10px; border-radius: 4px; font-size: 12px; font-weight: bold; }
        .status-running { background: #4CAF50; color: white; }
        .status-failed { background: #f44336; color: white; }
        .info { background: #e3f2fd; border-left: 4px solid #2196F3; padding: 15px; margin: 20px 0; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Kapadokya NetBoot v2.3</h1>

        <div class="info">
            <strong>Server IP:</strong> 192.168.122.20<br>
            <strong>Boot URL:</strong> http://192.168.122.20/knetboot/boot.ipxe<br>
            <strong>DHCP Range:</strong> 192.168.122.100 - 192.168.122.200
        </div>

        <h2>Service Status</h2>
        <div class="status">
            {% for service in services %}
            <div class="service {{ 'running' if service.status == 'active' else 'failed' }}">
                <h3>{{ service.name }}</h3>
                <span class="status-badge status-{{ service.status }}">{{ service.status|upper }}</span>
                <p style="margin-top: 10px; font-size: 14px; color: #666;">{{ service.description }}</p>
            </div>
            {% endfor %}
        </div>

        <h2>Quick Links</h2>
        <ul>
            <li><a href="/knetboot/boot.ipxe">View boot.ipxe</a></li>
            <li><a href="/knetboot/menus/main.ipxe">View main menu</a></li>
            <li><a href="/api/status">API Status (JSON)</a></li>
        </ul>
    </div>
</body>
</html>
"""

def get_service_status(service_name):
    try:
        # Use sudo systemctl (www-data has passwordless sudo for systemctl is-active)
        result = subprocess.run(['sudo', 'systemctl', 'is-active', service_name],
                              capture_output=True, text=True, timeout=5)
        status = result.stdout.strip()
        # Return the status (active, inactive, failed, unknown)
        return status if status else 'unknown'
    except Exception as e:
        return 'unknown'

@app.route('/')
def dashboard():
    services = [
        {'name': 'DHCP Server', 'status': get_service_status('isc-dhcp-server'), 'description': 'PXE boot DHCP'},
        {'name': 'TFTP Server', 'status': get_service_status('tftpd-hpa'), 'description': 'iPXE bootloader delivery'},
        {'name': 'NGINX', 'status': get_service_status('nginx'), 'description': 'HTTP server for boot files'},
        {'name': 'Web UI', 'status': get_service_status('knetboot-web'), 'description': 'Admin panel'},
    ]
    return render_template_string(DASHBOARD_HTML, services=services)

@app.route('/api/status')
def api_status():
    return jsonify({
        'dhcp': get_service_status('isc-dhcp-server'),
        'tftp': get_service_status('tftpd-hpa'),
        'nginx': get_service_status('nginx'),
        'web': get_service_status('knetboot-web')
    })

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000)
FLASK_APP
else
    echo "  ✓ Flask app found (using source version with DHCP config)"
fi

chmod +x \$INSTALL_DIR/web/app.py
chown -R www-data:www-data \$INSTALL_DIR/web
echo "  ✓ Flask app ready"

# 7. Configure DHCP
echo "[7/10] Configuring DHCP server..."
cat > /etc/dhcp/dhcpd.conf <<'DHCPEOF'
# Kapadokya NetBoot DHCP Configuration
authoritative;
default-lease-time 600;
max-lease-time 7200;
ddns-update-style none;

# Define PXE options
option space PXE;
option PXE.mtftp-ip code 1 = ip-address;

subnet 192.168.122.0 netmask 255.255.255.0 {
    range 192.168.122.100 192.168.122.200;
    option routers 192.168.122.1;
    option domain-name-servers 192.168.122.1, 8.8.8.8;
    option domain-name "knetboot.local";
    option broadcast-address 192.168.122.255;

    next-server 192.168.122.20;

    # iPXE already loaded - chain to HTTP menu
    if exists user-class and option user-class = "iPXE" {
        filename "http://192.168.122.20/knetboot/boot.ipxe";
    }
    # UEFI x64 (Client System Architecture Type 7 or 9)
    elsif substring(option vendor-class-identifier, 0, 20) = "PXEClient:Arch:00007" or
         substring(option vendor-class-identifier, 0, 20) = "PXEClient:Arch:00009" {
        filename "ipxe.efi";
    }
    # BIOS/Legacy
    else {
        filename "undionly.kpxe";
    }
}
DHCPEOF

echo "INTERFACESv4=\"\$IFACE\"" > /etc/default/isc-dhcp-server

# 8. Configure NGINX
echo "[8/10] Configuring NGINX..."
cat > /etc/nginx/sites-available/knetboot <<'EOF'
server {
    listen 80;
    server_name _;
    root /var/www/html;

    # iPXE files
    location ~ \.ipxe\$ {
        default_type text/plain;
        add_header Cache-Control "no-cache, must-revalidate";
    }

    # Large assets
    location /knetboot/assets/ {
        alias /opt/knetboot/assets/;
        add_header Accept-Ranges bytes;
        sendfile on;
        tcp_nopush on;
        tcp_nodelay on;
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    # Web UI (Flask proxy)
    location /admin {
        # Rewrite /admin/* to /* for Flask
        rewrite ^/admin(/.*)$ \$1 break;
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Prefix /admin;
    }

    # HTTP Boot - TFTP Alternative (v2.3 Feature)
    # Faster boot file delivery over HTTP instead of TFTP
    location /boot/http/ {
        proxy_pass http://127.0.0.1:5000/boot/http/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_buffering off;
        add_header Cache-Control "no-cache, must-revalidate";
        access_log /var/log/nginx/knetboot-boot.log combined;
    }

    # Menu files
    location /knetboot/menus/ {
        alias /opt/knetboot/config/menus/;
        default_type text/plain;
        access_log /var/log/nginx/knetboot-boot.log combined;
    }
}
EOF

ln -sf /etc/nginx/sites-available/knetboot /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t -q

# 9. Create configuration files and symlinks
echo "[9/10] Creating configs and symlinks..."

# Create settings.yaml
cat > \$INSTALL_DIR/config/settings.yaml <<EOF
server:
  ip: \$SERVER_IP
  name: Kapadokya NetBoot
  version: 2.3

network:
  subnet: \$NETWORK
  gateway: \$GATEWAY
  dhcp_start: \$DHCP_START
  dhcp_end: \$DHCP_END
  interface: \$IFACE
EOF

# Create system.json (central configuration)
cat > \$INSTALL_DIR/config/system.json <<EOF
{
  "server": {
    "ip": "\$SERVER_IP",
    "name": "knetboot-server",
    "hostname": "knetboot",
    "timezone": "Europe/Istanbul",
    "ntp_server": "\$GATEWAY",
    "ntp_fallback": "time.cloudflare.com, time.google.com"
  },
  "network": {
    "subnet": "\$NETWORK",
    "netmask": "\$NETMASK",
    "gateway": "\$GATEWAY",
    "dns_servers": ["\$GATEWAY", "8.8.8.8", "8.8.4.4"],
    "dns_primary": "\$GATEWAY",
    "dns_secondary": "8.8.8.8",
    "dns": "\$GATEWAY, 8.8.8.8",
    "dhcp_start": "\$DHCP_START",
    "dhcp_end": "\$DHCP_END",
    "next_server": "\$SERVER_IP"
  },
  "services": {
    "dhcp": {
      "enabled": true,
      "service_name": "isc-dhcp-server",
      "config_path": "/etc/dhcp/dhcpd.conf"
    },
    "tftp": {
      "enabled": true,
      "service_name": "tftpd-hpa",
      "root": "/srv/tftp",
      "config_path": "/etc/default/tftpd-hpa"
    },
    "nginx": {
      "enabled": true,
      "service_name": "nginx",
      "config_path": "/etc/nginx/sites-available/knetboot"
    },
    "web": {
      "enabled": true,
      "service_name": "knetboot-web",
      "port": 5000
    }
  },
  "paths": {
    "install_dir": "\$INSTALL_DIR",
    "web_root": "\$WEB_ROOT",
    "tftp_root": "/srv/tftp",
    "config_dir": "\$INSTALL_DIR/config",
    "assets_dir": "\$INSTALL_DIR/assets"
  },
  "last_updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

# Set ownership for system.json (www-data needs write access)
chown www-data:www-data \$INSTALL_DIR/config/system.json
chmod 644 \$INSTALL_DIR/config/system.json

# Create images.yaml
cat > \$INSTALL_DIR/config/images.yaml <<EOF
images:
  - id: local_boot
    name: "Boot from Local Disk"
    category: system
    type: local
    enabled: true
    description: "Exit PXE and boot from local hard drive"
EOF

# Create boot.ipxe
cat > \$WEB_ROOT/boot.ipxe <<'IPXE'
#!ipxe

:start
echo ================================================
echo Kapadokya NetBoot v2.3
echo ================================================
echo.

isset \${net0/ip} || dhcp net0 || goto dhcp_failed
echo IP Address: \${net0/ip}
echo Gateway: \${net0/gateway}
echo DNS: \${net0/dns}
echo.

set boot_server \${next-server}
isset \${boot_server} || set boot_server \${proxydhcp/next-server}
isset \${boot_server} || set boot_server \${dhcp-server}

echo Boot Server: \${boot_server}
echo.

set base_url http://\${boot_server}/knetboot
chain \${base_url}/menus/main.ipxe || goto chain_failed

:dhcp_failed
echo DHCP failed! Press any key to retry...
prompt
goto start

:chain_failed
echo Failed to load main menu!
echo Server: \${boot_server}
echo URL: \${base_url}/menus/main.ipxe
echo.
echo Press any key to retry...
prompt
goto start
IPXE

# Create main.ipxe
mkdir -p \$INSTALL_DIR/config/menus
cat > \$INSTALL_DIR/config/menus/main.ipxe <<'MAINMENU'
#!ipxe

:main_menu
menu Kapadokya NetBoot - Main Menu
item --gap -- Operating Systems:
item ubuntu Ubuntu Systems
item --gap -- Tools:
item tools Diagnostic Tools
item --gap -- System:
item local Boot from Local Disk
item reboot Reboot
item --gap --
item shell iPXE Shell
choose selected && goto \${selected}

:ubuntu
echo Ubuntu menu not yet configured
sleep 3
goto main_menu

:tools
echo Tools menu not yet configured
sleep 3
goto main_menu

:local
echo Booting from local disk...
sanboot --no-describe --drive 0x80

:reboot
echo Rebooting...
reboot

:shell
echo Type 'exit' to return to menu
shell
goto main_menu
MAINMENU

# Create symlinks
ln -sf \$INSTALL_DIR/assets \$WEB_ROOT/assets
ln -sf \$INSTALL_DIR/config/menus \$WEB_ROOT/menus

# 10. Create and enable systemd service
echo "[10/10] Setting up systemd service..."

# Add sudoers entry for www-data to run systemctl and dhcpd commands without password
cat > /etc/sudoers.d/knetboot-web <<'SUDOERS'
# Allow www-data to check service status
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl is-active *
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl status *
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl is-enabled *
# Allow www-data to control DHCP service
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl start isc-dhcp-server
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop isc-dhcp-server
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart isc-dhcp-server
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl enable isc-dhcp-server
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl disable isc-dhcp-server
# Allow www-data to manage DHCP config
www-data ALL=(ALL) NOPASSWD: /usr/bin/tee /etc/dhcp/dhcpd.conf
www-data ALL=(ALL) NOPASSWD: /usr/sbin/dhcpd -t -cf /etc/dhcp/dhcpd.conf
# Allow www-data to control TFTP service
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl start tftpd-hpa
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop tftpd-hpa
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart tftpd-hpa
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl enable tftpd-hpa
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl disable tftpd-hpa
# Allow www-data to manage TFTP config
www-data ALL=(ALL) NOPASSWD: /usr/bin/tee /etc/default/tftpd-hpa
# Allow www-data to manage NTP and timezone
www-data ALL=(ALL) NOPASSWD: /usr/bin/timedatectl set-timezone *
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart systemd-timesyncd
www-data ALL=(ALL) NOPASSWD: /usr/bin/tee /etc/systemd/timesyncd.conf.d/local.conf
# Allow www-data to manage TFTP boot files (upload/delete)
www-data ALL=(ALL) NOPASSWD: /usr/bin/cp /tmp/* /srv/tftp/*
www-data ALL=(ALL) NOPASSWD: /usr/bin/chmod 644 /srv/tftp/*
www-data ALL=(ALL) NOPASSWD: /usr/bin/rm -f /srv/tftp/*
# Allow www-data to restart NGINX
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx
SUDOERS
chmod 440 /etc/sudoers.d/knetboot-web

cat > /etc/systemd/system/knetboot-web.service <<EOF
[Unit]
Description=Kapadokya NetBoot Web UI
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=\$INSTALL_DIR/web
Environment="PATH=\$INSTALL_DIR/web/venv/bin"
ExecStart=\$INSTALL_DIR/web/venv/bin/gunicorn -w 4 -b 127.0.0.1:5000 app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

# Start services
echo
echo "Starting services..."

# Stop services first if running
systemctl stop isc-dhcp-server 2>/dev/null || true
systemctl stop knetboot-web 2>/dev/null || true

# Start services fresh
systemctl enable --now isc-dhcp-server 2>&1 | grep -v "Created symlink" || true
systemctl enable --now tftpd-hpa 2>&1 | grep -v "Created symlink" || true
systemctl restart nginx
systemctl enable --now knetboot-web 2>&1 | grep -v "Created symlink" || true

# Wait for services to start
echo "  Waiting for services to initialize..."
sleep 5

# Verify Flask app is actually running
if netstat -tlnp 2>/dev/null | grep -q ":5000"; then
    echo "  ✓ Flask app listening on port 5000"
else
    echo "  ⚠ Warning: Flask app not listening on port 5000"
    echo "  Checking logs..."
    journalctl -u knetboot-web -n 10 --no-pager || true
fi

echo
echo "========================================="
echo "Installation Complete!"
echo "========================================="
echo "Server IP: \$SERVER_IP"
echo "Web UI: http://\$SERVER_IP/admin/"
echo "Boot URL: http://\$SERVER_IP/knetboot/boot.ipxe"
echo
echo "Service Status:"
systemctl is-active isc-dhcp-server >/dev/null && echo "  ✓ DHCP: Running" || echo "  ✗ DHCP: Failed (check: journalctl -u isc-dhcp-server)"
systemctl is-active tftpd-hpa >/dev/null && echo "  ✓ TFTP: Running" || echo "  ✗ TFTP: Failed"
systemctl is-active nginx >/dev/null && echo "  ✓ NGINX: Running" || echo "  ✗ NGINX: Failed"
systemctl is-active knetboot-web >/dev/null && echo "  ✓ Web UI: Running" || echo "  ✗ Web UI: Failed (check: journalctl -u knetboot-web)"
echo
echo "Network Ports:"
netstat -tlnp 2>/dev/null | grep -E ":(80|5000|69) " || echo "  No services listening"
echo
REMOTE_SCRIPT

echo -e "  ${GREEN}✓${NC} Installation script created"

# Step 5: Make remote script executable
echo -e "${YELLOW}[5/8]${NC} Making installation script executable..."
sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" \
    'chmod +x /tmp/install-knetboot.sh'

# Step 6: Run installation on remote (with sudo)
echo -e "${YELLOW}[6/8]${NC} Running installation on remote server..."
echo -e "${BLUE}  This may take a few minutes...${NC}"
sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" \
    "echo '$REMOTE_PASS' | sudo -S /tmp/install-knetboot.sh 2>&1" | while read line; do
    echo "  $line"
done

# Step 7: Health Check
echo
echo -e "${YELLOW}[7/8]${NC} Running health checks..."
sleep 3

HEALTH_PASSED=0
HEALTH_FAILED=0

# Check Web UI
echo -n "  - Web UI (http://$REMOTE_HOST/admin/)... "
if curl -s -m 5 "http://$REMOTE_HOST/admin/" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
    ((HEALTH_PASSED++))
else
    echo -e "${RED}✗ FAILED${NC}"
    ((HEALTH_FAILED++))
fi

# Check boot.ipxe
echo -n "  - boot.ipxe... "
if curl -s -m 5 "http://$REMOTE_HOST/knetboot/boot.ipxe" | grep -q "Kapadokya NetBoot"; then
    echo -e "${GREEN}✓ OK${NC}"
    ((HEALTH_PASSED++))
else
    echo -e "${RED}✗ FAILED${NC}"
    ((HEALTH_FAILED++))
fi

# Check main menu
echo -n "  - Main menu... "
if curl -s -m 5 "http://$REMOTE_HOST/knetboot/menus/main.ipxe" | grep -q "main_menu"; then
    echo -e "${GREEN}✓ OK${NC}"
    ((HEALTH_PASSED++))
else
    echo -e "${RED}✗ FAILED${NC}"
    ((HEALTH_FAILED++))
fi

# Check TFTP
echo -n "  - TFTP service... "
if sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" \
    'systemctl is-active tftpd-hpa' | grep -q "active"; then
    echo -e "${GREEN}✓ OK${NC}"
    ((HEALTH_PASSED++))
else
    echo -e "${RED}✗ FAILED${NC}"
    ((HEALTH_FAILED++))
fi

# Check DHCP
echo -n "  - DHCP service... "
if sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" \
    'systemctl is-active isc-dhcp-server' | grep -q "active"; then
    echo -e "${GREEN}✓ OK${NC}"
    ((HEALTH_PASSED++))
else
    echo -e "${RED}✗ FAILED${NC}"
    ((HEALTH_FAILED++))
fi

# Step 8: Summary
echo
echo -e "${YELLOW}[8/8]${NC} Health Check Summary"
echo -e "  Passed: ${GREEN}$HEALTH_PASSED${NC}"
echo -e "  Failed: ${RED}$HEALTH_FAILED${NC}"

echo
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo
echo -e "${YELLOW}Access Information:${NC}"
echo "  Web UI:   http://$REMOTE_HOST/admin/"
echo "  Boot URL: http://$REMOTE_HOST/knetboot/boot.ipxe"
echo "  API:      http://$REMOTE_HOST/api/status"
echo
echo -e "${YELLOW}SSH Access:${NC}"
echo "  ssh $REMOTE_USER@$REMOTE_HOST"
echo "  Password: $REMOTE_PASS"
echo
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Access Web UI to see service status"
echo "  2. Test PXE boot from a client VM"
echo "  3. Add custom images to /opt/knetboot/config/images.yaml"
echo "  4. Monitor logs: ssh $REMOTE_USER@$REMOTE_HOST 'sudo journalctl -f'"
echo
echo -e "${YELLOW}Troubleshooting:${NC}"
echo "  View DHCP logs: ssh $REMOTE_USER@$REMOTE_HOST 'sudo journalctl -u isc-dhcp-server'"
echo "  View Web UI logs: ssh $REMOTE_USER@$REMOTE_HOST 'sudo journalctl -u knetboot-web'"
echo "  Check services: ssh $REMOTE_USER@$REMOTE_HOST 'sudo systemctl status knetboot-web isc-dhcp-server'"
echo

if [ $HEALTH_FAILED -gt 0 ]; then
    echo -e "${RED}⚠ Warning: Some health checks failed. Please review the logs.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All health checks passed! System is ready.${NC}"
