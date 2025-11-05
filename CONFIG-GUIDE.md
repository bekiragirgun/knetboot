# Kapadokya NetBoot - Konfigürasyon Rehberi

## 📋 İçindekiler

1. [Genel Bakış](#genel-bakış)
2. [DHCP Server Konfigürasyonu](#dhcp-server-konfigürasyonu)
3. [TFTP Server Konfigürasyonu](#tftp-server-konfigürasyonu)
4. [NGINX Konfigürasyonu](#nginx-konfigürasyonu)
5. [Flask Web UI Konfigürasyonu](#flask-web-ui-konfigürasyonu)
6. [Network Ayarları](#network-ayarları)
7. [Güvenlik Ayarları](#güvenlik-ayarları)
8. [Performans Optimizasyonu](#performans-optimizasyonu)

---

## Genel Bakış

Kapadokya NetBoot sistemi 4 ana servisten oluşur:

```
┌─────────────────────────────────────┐
│  DHCP Server (isc-dhcp-server)      │  Port: 67/68 UDP
│  ↓ IP adresi + boot bilgisi         │
├─────────────────────────────────────┤
│  TFTP Server (tftpd-hpa)            │  Port: 69 UDP
│  ↓ iPXE bootloader (~1MB)           │
├─────────────────────────────────────┤
│  HTTP Server (NGINX)                │  Port: 80 TCP
│  ↓ Boot menus + Images (GB'lar)    │
├─────────────────────────────────────┤
│  Web UI (Flask + Gunicorn)          │  Port: 5000 (internal)
│  → Admin panel                      │
└─────────────────────────────────────┘
```

---

## DHCP Server Konfigürasyonu

### Dosya Konumu
```bash
/etc/dhcp/dhcpd.conf              # Ana konfigürasyon
/etc/default/isc-dhcp-server      # Interface ayarları
```

### Template Kullanımı

Template dosyası: [config/dhcpd.conf.template](config/dhcpd.conf.template)

**Özelleştirilebilir değerler:**

| Değişken | Açıklama | Varsayılan | Örnek |
|----------|----------|------------|-------|
| `{{NETWORK}}` | Subnet adresi | 192.168.122.0 | 10.0.0.0 |
| `{{NETMASK}}` | Alt ağ maskesi | 255.255.255.0 | 255.255.0.0 |
| `{{DHCP_START}}` | IP havuzu başlangıç | 192.168.122.100 | 10.0.0.100 |
| `{{DHCP_END}}` | IP havuzu bitiş | 192.168.122.200 | 10.0.0.250 |
| `{{GATEWAY}}` | Ağ geçidi | 192.168.122.1 | 10.0.0.1 |
| `{{DNS_SERVERS}}` | DNS sunucular | 192.168.122.1 | 8.8.8.8, 1.1.1.1 |
| `{{SERVER_IP}}` | PXE server IP | 192.168.122.20 | 10.0.0.20 |
| `{{DOMAIN_NAME}}` | Domain adı | knetboot.local | lab.company.com |

### Manuel Konfigürasyon

```bash
# 1. Config dosyasını düzenle
sudo nano /etc/dhcp/dhcpd.conf

# 2. Interface belirle
sudo nano /etc/default/isc-dhcp-server
# INTERFACESv4="enp1s0"

# 3. Syntax kontrol
sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf

# 4. Servisi yeniden başlat
sudo systemctl restart isc-dhcp-server

# 5. Durumu kontrol et
sudo systemctl status isc-dhcp-server
```

### Sabit IP Atama

DHCP config'e ekle:

```bash
# Lab PC 01 için sabit IP
host lab-pc-01 {
    hardware ethernet 00:11:22:33:44:55;
    fixed-address 192.168.122.101;
}

# Lab PC 02 için sabit IP
host lab-pc-02 {
    hardware ethernet 66:77:88:99:AA:BB;
    fixed-address 192.168.122.102;
}
```

### Log İnceleme

```bash
# Canlı log takibi
sudo journalctl -u isc-dhcp-server -f

# Son 50 satır
sudo journalctl -u isc-dhcp-server -n 50

# DHCP leases (verilen IP'ler)
cat /var/lib/dhcp/dhcpd.leases
```

---

## TFTP Server Konfigürasyonu

### Dosya Konumu
```bash
/etc/default/tftpd-hpa            # Konfigürasyon
/srv/tftp/                        # Root dizin
```

### Template Kullanımı

Template dosyası: [config/tftpd-hpa.conf.template](config/tftpd-hpa.conf.template)

### Temel Ayarlar

```bash
# /etc/default/tftpd-hpa
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/srv/tftp"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="--secure"
```

### iPXE Bootloader'ları İndirme

```bash
cd /srv/tftp
sudo wget http://boot.ipxe.org/undionly.kpxe  # BIOS
sudo wget http://boot.ipxe.org/ipxe.efi        # UEFI
sudo chown tftp:tftp *
sudo chmod 644 *
```

### Test

```bash
# Local test
tftp localhost -c get undionly.kpxe /tmp/test
file /tmp/test

# Remote test
tftp 192.168.122.20 -c get undionly.kpxe /tmp/test
```

### Sorun Giderme

```bash
# Servis durumu
sudo systemctl status tftpd-hpa

# Port dinleniyor mu?
sudo netstat -ulnp | grep :69

# Verbose logging
# /etc/default/tftpd-hpa içinde:
TFTP_OPTIONS="--secure --verbose"
sudo systemctl restart tftpd-hpa
sudo journalctl -u tftpd-hpa -f
```

---

## NGINX Konfigürasyonu

### Dosya Konumu
```bash
/etc/nginx/sites-available/knetboot    # Konfigürasyon
/etc/nginx/sites-enabled/knetboot      # Symlink
/var/www/html/knetboot/                # Document root
```

### Template Kullanımı

Template dosyası: [config/nginx.conf.template](config/nginx.conf.template)

### Manuel Düzenleme

```bash
# Config dosyasını düzenle
sudo nano /etc/nginx/sites-available/knetboot

# Syntax kontrol
sudo nginx -t

# Yeniden başlat
sudo systemctl reload nginx
```

### SSL/HTTPS Ekleme (Opsiyonel)

```bash
# Self-signed sertifika oluştur
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/knetboot.key \
  -out /etc/ssl/certs/knetboot.crt

# NGINX config'e ekle:
server {
    listen 443 ssl http2;
    ssl_certificate /etc/ssl/certs/knetboot.crt;
    ssl_certificate_key /etc/ssl/private/knetboot.key;
    # ... diğer ayarlar
}
```

### Performans Ayarları

```nginx
# /etc/nginx/nginx.conf
worker_processes auto;
worker_connections 2048;
keepalive_timeout 65;
client_max_body_size 10G;  # Büyük ISO/squashfs için
```

---

## Flask Web UI Konfigürasyonu

### Dosya Konumu
```bash
/opt/knetboot/web/app.py                    # Flask app
/opt/knetboot/web/venv/                     # Python venv
/etc/systemd/system/knetboot-web.service    # Systemd service
/etc/sudoers.d/knetboot-web                 # Sudo permissions
```

### Python Dependencies

```bash
cd /opt/knetboot/web
source venv/bin/activate
pip list

# Kurulu paketler:
# - Flask (web framework)
# - PyYAML (config parsing)
# - Gunicorn (WSGI server)
```

### Systemd Service

```ini
[Unit]
Description=Kapadokya NetBoot Web UI
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/knetboot/web
Environment="PATH=/opt/knetboot/web/venv/bin"
ExecStart=/opt/knetboot/web/venv/bin/gunicorn -w 4 -b 127.0.0.1:5000 app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### Gunicorn Ayarları

```bash
# Worker sayısı: CPU count x 2 + 1
# 2 CPU = 5 workers
gunicorn -w 5 -b 127.0.0.1:5000 app:app

# Timeout artırma (yavaş işlemler için)
gunicorn -w 4 -b 127.0.0.1:5000 --timeout 120 app:app
```

### Debugging

```bash
# Flask app logları
sudo journalctl -u knetboot-web -f

# Manuel çalıştırma (debug için)
cd /opt/knetboot/web
source venv/bin/activate
python3 app.py
# http://127.0.0.1:5000 adresinden erişilebilir
```

---

## Network Ayarları

### Network Interface Tespit

```bash
# Tüm interface'leri listele
ip addr show

# Aktif interface'leri göster
ip link show | grep UP

# DHCP dinleyecek interface
ip -o -4 addr show | grep 192.168.122
```

### Firewall Ayarları

#### UFW (Ubuntu)

```bash
# DHCP
sudo ufw allow 67/udp
sudo ufw allow 68/udp

# TFTP
sudo ufw allow 69/udp

# HTTP
sudo ufw allow 80/tcp

# HTTPS (opsiyonel)
sudo ufw allow 443/tcp
```

#### iptables

```bash
# DHCP
sudo iptables -A INPUT -p udp --dport 67:68 -j ACCEPT

# TFTP
sudo iptables -A INPUT -p udp --dport 69 -j ACCEPT

# HTTP
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# Kaydet
sudo iptables-save > /etc/iptables/rules.v4
```

---

## Güvenlik Ayarları

### 1. Sudoers Permissions

```bash
# /etc/sudoers.d/knetboot-web
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl is-active *
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl status *

# İzinler
sudo chmod 440 /etc/sudoers.d/knetboot-web
```

### 2. Dosya İzinleri

```bash
# TFTP root
sudo chown -R tftp:tftp /srv/tftp
sudo chmod 755 /srv/tftp
sudo chmod 644 /srv/tftp/*

# Web UI
sudo chown -R www-data:www-data /opt/knetboot/web
sudo chmod 755 /opt/knetboot/web
sudo chmod 644 /opt/knetboot/web/app.py
```

### 3. NGINX Security Headers

```nginx
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
```

---

## Performans Optimizasyonu

### NGINX

```nginx
# Gzip compression
gzip on;
gzip_comp_level 6;
gzip_types text/plain text/css application/json;

# Sendfile
sendfile on;
tcp_nopush on;
tcp_nodelay on;

# Cache
location /knetboot/assets/ {
    expires 7d;
    add_header Cache-Control "public, immutable";
}
```

### TFTP

```bash
# Büyük block size (hız artışı)
TFTP_OPTIONS="--secure --blocksize 8192"
```

### DHCP

```bash
# Lease time azaltma (hızlı release)
default-lease-time 300;
max-lease-time 600;
```

---

## Hızlı Referans

### Tüm Servisleri Kontrol

```bash
systemctl status isc-dhcp-server tftpd-hpa nginx knetboot-web
```

### Tüm Servisleri Yeniden Başlat

```bash
sudo systemctl restart isc-dhcp-server tftpd-hpa nginx knetboot-web
```

### Port Dinleme Kontrolü

```bash
sudo netstat -tlnup | grep -E ":(67|69|80|5000) "
```

### Log Takibi (Tümü)

```bash
sudo journalctl -f -u isc-dhcp-server -u tftpd-hpa -u nginx -u knetboot-web
```

---

**Son Güncelleme:** 2025-11-04
**Versiyon:** 2.0
**Yazar:** Claude Code & Bekir
