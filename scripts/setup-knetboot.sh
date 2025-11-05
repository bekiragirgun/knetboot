#!/bin/bash
# Kapadokya NetBoot - Automated Setup Script
# Version: 1.0

set -e

echo "==================================="
echo "Kapadokya NetBoot Setup v1.0"
echo "==================================="
echo

# Root check
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run as root (sudo)"
    exit 1
fi

# Değişkenler
INSTALL_DIR="/opt/knetboot"
WEB_ROOT="/var/www/html/knetboot"
TFTP_ROOT="/srv/tftp"

# 1. Paket kurulumu
echo "[1/8] Installing packages..."
apt update -qq
apt install -y nginx python3 python3-pip python3-venv \
    isc-dhcp-server tftpd-hpa curl wget

echo "[2/8] Creating directory structure..."
mkdir -p $INSTALL_DIR/{config/{menus,themes},web,scripts,assets/{ipxe,images,kernels}}
mkdir -p $WEB_ROOT
mkdir -p $TFTP_ROOT

# 3. iPXE binaries
echo "[3/8] Downloading iPXE bootloaders..."
cd $TFTP_ROOT
if [ ! -f undionly.kpxe ]; then
    wget -q http://boot.ipxe.org/undionly.kpxe -O undionly.kpxe
fi
if [ ! -f ipxe.efi ]; then
    wget -q http://boot.ipxe.org/ipxe.efi -O ipxe.efi
fi
chmod 644 *.kpxe *.efi
chown tftp:tftp *

# 4. Python virtual environment
echo "[4/8] Setting up Python environment..."
cd $INSTALL_DIR/web
python3 -m venv venv
source venv/bin/activate
pip install -q --upgrade pip
pip install -q flask pyyaml gunicorn
deactivate

# 5. DHCP yapılandırma
echo "[5/8] Configuring DHCP server..."
read -p "Enter server IP address [192.168.27.254]: " SERVER_IP
SERVER_IP=${SERVER_IP:-192.168.27.254}
read -p "Enter network [192.168.27.0]: " NETWORK
NETWORK=${NETWORK:-192.168.27.0}
read -p "Enter DHCP range start [192.168.27.100]: " DHCP_START
DHCP_START=${DHCP_START:-192.168.27.100}
read -p "Enter DHCP range end [192.168.27.200]: " DHCP_END
DHCP_END=${DHCP_END:-192.168.27.200}
read -p "Enter gateway [192.168.27.1]: " GATEWAY
GATEWAY=${GATEWAY:-192.168.27.1}

cat > /etc/dhcp/dhcpd.conf <<EOF
# Kapadokya NetBoot DHCP Config
# Generated: $(date)

subnet $NETWORK netmask 255.255.255.0 {
    range $DHCP_START $DHCP_END;
    option routers $GATEWAY;
    option domain-name-servers $GATEWAY;
    option domain-name "knetboot.local";

    next-server $SERVER_IP;

    # BIOS vs UEFI detection
    if exists user-class and option user-class = "iPXE" {
        filename "http://$SERVER_IP/knetboot/boot.ipxe";
    } elsif option arch = 00:07 or option arch = 00:09 {
        filename "ipxe.efi";
    } else {
        filename "undionly.kpxe";
    }
}
EOF

# Interface detection
DEFAULT_IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
read -p "Enter network interface [$DEFAULT_IFACE]: " IFACE
IFACE=${IFACE:-$DEFAULT_IFACE}

sed -i "s/INTERFACESv4=\"\"/INTERFACESv4=\"$IFACE\"/" /etc/default/isc-dhcp-server

# 6. NGINX yapılandırma
echo "[6/8] Configuring NGINX..."
cat > /etc/nginx/sites-available/knetboot <<EOF
server {
    listen 80;
    server_name _;
    root /var/www/html;

    # iPXE dosyaları
    location ~ \.ipxe$ {
        default_type text/plain;
        add_header Cache-Control "no-cache, must-revalidate";
    }

    # Assets
    location /knetboot/assets/ {
        alias $INSTALL_DIR/assets/;
        add_header Accept-Ranges bytes;
        sendfile on;
        tcp_nopush on;
        tcp_nodelay on;
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    # Web UI
    location /admin/ {
        proxy_pass http://127.0.0.1:5000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # Boot log
    location /knetboot/menus/ {
        alias $INSTALL_DIR/config/menus/;
        default_type text/plain;
        access_log /var/log/nginx/knetboot-boot.log combined;
    }
}
EOF

ln -sf /etc/nginx/sites-available/knetboot /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t

# 7. Symlinks
echo "[7/8] Creating symlinks..."
ln -sf $INSTALL_DIR/assets $WEB_ROOT/assets
ln -sf $INSTALL_DIR/config/menus $WEB_ROOT/menus

# Config dosyası
cat > $INSTALL_DIR/config/settings.yaml <<EOF
server:
  ip: $SERVER_IP
  name: Kapadokya NetBoot

network:
  subnet: $NETWORK
  gateway: $GATEWAY
  dhcp_start: $DHCP_START
  dhcp_end: $DHCP_END
EOF

# 8. Systemd service
echo "[8/8] Creating systemd service..."
cat > /etc/systemd/system/knetboot-web.service <<EOF
[Unit]
Description=Kapadokya NetBoot Web UI
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=$INSTALL_DIR/web
Environment="PATH=$INSTALL_DIR/web/venv/bin"
ExecStart=$INSTALL_DIR/web/venv/bin/gunicorn -w 4 -b 127.0.0.1:5000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

# Servisleri başlat
echo
echo "Starting services..."
systemctl enable --now isc-dhcp-server
systemctl enable --now tftpd-hpa
systemctl restart nginx

echo
echo "==================================="
echo "Installation Complete!"
echo "==================================="
echo "Server IP: $SERVER_IP"
echo "Web UI: http://$SERVER_IP/admin/ (will be available after init-config.sh)"
echo
echo "Next steps:"
echo "1. cd $INSTALL_DIR && ./scripts/init-config.sh"
echo "2. systemctl start knetboot-web"
echo "3. Upload first image via Web UI"
echo "4. Test PXE boot from client"
echo
