#!/bin/bash
# Kapadokya NetBoot - Initialize Default Configuration
# Version: 1.0

INSTALL_DIR="/opt/knetboot"
WEB_ROOT="/var/www/html/knetboot"

if [ ! -d "$INSTALL_DIR" ]; then
    echo "ERROR: $INSTALL_DIR does not exist. Run setup-knetboot.sh first."
    exit 1
fi

echo "Initializing knetboot configuration..."

# Get server IP from settings
SERVER_IP=$(grep 'ip:' $INSTALL_DIR/config/settings.yaml | awk '{print $2}')
if [ -z "$SERVER_IP" ]; then
    echo "WARNING: Could not find server IP in settings.yaml, using 192.168.27.254"
    SERVER_IP="192.168.27.254"
fi

# 1. Default images.yaml
cat > $INSTALL_DIR/config/images.yaml <<EOF
# Kapadokya NetBoot - Image Database
# Format: YAML

images:
  - id: local_boot
    name: "Boot from Local Disk"
    category: system
    type: local
    enabled: true
    description: "Exit PXE and boot from local hard drive"
EOF

# 2. Default boot.ipxe
cat > $WEB_ROOT/boot.ipxe <<'EOF'
#!ipxe

# Kapadokya NetBoot - Main Entry Point
# Auto-generated

:start
echo ================================================
echo Kapadokya NetBoot v1.0
echo ================================================
echo.

# DHCP
isset ${net0/ip} || dhcp net0 || goto dhcp_failed
echo IP Address: ${net0/ip}
echo Gateway: ${net0/gateway}
echo DNS: ${net0/dns}
echo.

# Boot server
set boot_server ${next-server}
isset ${boot_server} || set boot_server ${proxydhcp/next-server}
isset ${boot_server} || set boot_server ${dhcp-server}

echo Boot Server: ${boot_server}
echo.

# Chain to main menu
set base_url http://${boot_server}/knetboot
chain ${base_url}/menus/main.ipxe || goto chain_failed

:dhcp_failed
echo DHCP failed! Press any key to retry...
prompt
goto start

:chain_failed
echo Failed to load main menu!
echo Server: ${boot_server}
echo URL: ${base_url}/menus/main.ipxe
echo.
echo Press any key to retry...
prompt
goto start
EOF

# 3. Default main.ipxe
cat > $INSTALL_DIR/config/menus/main.ipxe <<EOF
#!ipxe

:main_menu
menu Kapadokya NetBoot - Main Menu
item --gap -- Boot Options:
item local Boot from Local Disk
item --gap -- System:
item shell iPXE Shell
item reboot Reboot
item exit Exit to BIOS
item --gap --
choose --timeout 30000 --default local selected && goto \${selected}

:local
echo Booting from local disk...
exit

:shell
shell

:reboot
reboot

:exit
exit
EOF

echo "Default configuration created!"
echo
echo "Files created:"
echo "  - $INSTALL_DIR/config/images.yaml"
echo "  - $WEB_ROOT/boot.ipxe"
echo "  - $INSTALL_DIR/config/menus/main.ipxe"
echo
echo "Boot URL: http://$SERVER_IP/knetboot/boot.ipxe"
echo
echo "You can now:"
echo "1. Test boot.ipxe: curl http://$SERVER_IP/knetboot/boot.ipxe"
echo "2. Start web UI: systemctl start knetboot-web"
echo "3. Access admin: http://$SERVER_IP/admin/"
