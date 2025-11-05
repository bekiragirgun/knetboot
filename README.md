# Kapadokya NetBoot (knetboot)

**Version:** 2.3.0
**Status:** Production Ready - Full Web Management + HTTP Boot

netboot.xyz'den ilham alınarak tasarlanmış, hibrit PXE network boot sistemi.

## Özellikler

- ✅ **Web UI**: Flask tabanlı admin panel ile image ve menu yönetimi
- ✅ **DHCP Yönetimi**: Web arayüzü ile DHCP yapılandırma ve toggle switch (ON/OFF)
- ✅ **Gerçek Zamanlı Durum**: Servislerin anlık durumu (DHCP, TFTP, NGINX, Web UI)
- ✅ **iPXE Boot**: HTTP üzerinden hızlı boot
- ✅ **Çoklu OS**: Ubuntu, Debian, CentOS, Fedora desteği
- ✅ **Custom Images**: Golden image'lar için destek
- ✅ **Live Boot**: RAM'de çalışan sistemler
- ✅ **Bare Metal**: Docker olmadan direkt kurulum

## Hızlı Başlangıç

### 1. Kurulum

```bash
cd /home/bekir/Projects/kapadokya_scripts/knetboot

# Root olarak çalıştır
sudo ./scripts/setup-knetboot.sh
```

Interactive sorular:
- Server IP: `192.168.27.254`
- Network: `192.168.27.0`
- DHCP Range: `192.168.27.100 - 192.168.27.200`
- Gateway: `192.168.27.1`
- Network Interface: `ens33` (veya otomatik tespit)

### 2. İlk Yapılandırma

```bash
cd /opt/knetboot
sudo ./scripts/init-config.sh
```

### 3. Web UI Başlat

```bash
sudo systemctl start knetboot-web
sudo systemctl enable knetboot-web
```

### 4. Erişim

- **Admin Panel**: http://SERVER_IP/admin/
  - Dashboard: Servis durumları ve quick actions
  - DHCP Config: Network ayarları ve toggle switch (ON/OFF)
  - TFTP Config: Boot dosyaları ve toggle switch (ON/OFF)
  - Images: Image yönetimi
  - Menus: iPXE menü yönetimi
  - Settings: Server, NTP, DNS, Timezone ayarları
- **Boot URL**: http://SERVER_IP/knetboot/boot.ipxe
- **API Status**: http://SERVER_IP/api/status

## Dizin Yapısı

```
/opt/knetboot/
├── config/
│   ├── images.yaml          # Image database
│   ├── settings.yaml         # Server config
│   └── menus/                # iPXE menu files
├── web/
│   ├── app.py               # Flask application
│   ├── templates/           # HTML templates
│   └── static/              # CSS, JS
├── scripts/
│   ├── setup-knetboot.sh    # Installation script
│   ├── init-config.sh       # Initial config
│   └── menu-generator.py    # Menu generator
└── assets/
    ├── ipxe/                # Bootloader binaries
    ├── ubuntu/              # Ubuntu images
    ├── kapadokya/           # Custom golden images
    └── tools/               # Diagnostic tools

/var/www/html/knetboot/
├── boot.ipxe                # Main entry point
├── menus/                   # Symlink → /opt/knetboot/config/menus/
└── assets/                  # Symlink → /opt/knetboot/assets/

/srv/tftp/
├── undionly.kpxe            # BIOS bootloader
└── ipxe.efi                 # UEFI bootloader
```

## Image Ekleme

### Manuel (images.yaml)

`/opt/knetboot/config/images.yaml` dosyasını düzenle:

```yaml
images:
  - id: ubuntu_2404_desktop
    name: "Ubuntu 24.04 Desktop"
    category: ubuntu
    type: live
    kernel: assets/ubuntu/24.04/desktop/vmlinuz
    initrd: assets/ubuntu/24.04/desktop/initrd
    squashfs: assets/ubuntu/24.04/desktop/filesystem.squashfs
    boot_args: "boot=casper netboot=url ip=dhcp"
    enabled: true
    size: "3.2 GB"
    description: "Ubuntu 24.04 LTS Desktop - Live boot"
```

Sonra menüleri regenerate et:

```bash
cd /opt/knetboot
python3 scripts/menu-generator.py
```

### Web UI (Gelecek Özellik)

Admin panelden "Add Image" butonu ile (TODO: implement)

## Boot İşleyişi

1. Client → PXE boot
2. DHCP → IP + TFTP server bilgisi
3. TFTP → iPXE bootloader indir (~1MB)
4. iPXE → HTTP'den boot.ipxe al
5. boot.ipxe → main.ipxe chain
6. Kullanıcı menüden seçim
7. iPXE → Kernel/initrd/squashfs indir (HTTP)
8. Boot!

## Test (Libvirt)

### Test Ortamı

```
Host Machine
├─ knetboot Server VM (Ubuntu 24.04 Server)
│  └─ IP: 192.168.122.254
└─ Test Client VM (PXE boot)
   └─ IP: DHCP (192.168.122.100-200)
```

### knetboot Server VM Oluştur

```bash
virt-install \
  --name knetboot-server \
  --ram 4096 \
  --vcpus 2 \
  --disk size=100 \
  --network network=default \
  --cdrom /path/to/ubuntu-24.04-server.iso \
  --graphics vnc \
  --os-variant ubuntu24.04
```

Server VM'de knetboot'u kur:
1. Ubuntu Server 24.04 kur
2. SSH aktif et
3. Bu repo'yu klonla veya kopyala
4. `sudo ./scripts/setup-knetboot.sh` çalıştır

### Test Client VM Oluştur

```bash
virt-install \
  --name knetboot-client \
  --ram 4096 \
  --vcpus 2 \
  --disk size=30 \
  --network network=default \
  --pxe \
  --boot network,hd \
  --graphics vnc \
  --os-variant ubuntu24.04
```

**NOT:** Libvirt default network'te DHCP'yi devre dışı bırak (knetboot DHCP kullanacak):

```bash
virsh net-edit default
# <dhcp> bölümünü sil veya comment out
virsh net-destroy default
virsh net-start default
```

### Test Senaryoları

1. ✅ **PXE Boot**: Client VM boot → iPXE menü görülmeli
2. ✅ **Local Boot**: "Boot from Local Disk" seç → local disk boot
3. ✅ **Web UI**: http://192.168.122.254/admin/ aç
4. ✅ **Menu Regenerate**: Web UI'dan "Regenerate Menus"

## Servis Yönetimi

```bash
# Durum kontrolü
systemctl status knetboot-web
systemctl status isc-dhcp-server
systemctl status tftpd-hpa
systemctl status nginx

# Yeniden başlat
systemctl restart knetboot-web
systemctl restart isc-dhcp-server

# Loglar
journalctl -u knetboot-web -f
journalctl -u isc-dhcp-server -f
tail -f /var/log/nginx/knetboot-boot.log
```

## Sorun Giderme

### PXE Boot Çalışmıyor

```bash
# DHCP log kontrol
journalctl -u isc-dhcp-server -n 50

# TFTP test
tftp SERVER_IP -c get undionly.kpxe /tmp/test
```

### Web UI Açılmıyor

```bash
# Service kontrol
systemctl status knetboot-web

# Port kontrol
netstat -tlnp | grep 5000

# Log kontrol
journalctl -u knetboot-web -n 50
```

### Menu Yüklenmiyor

```bash
# HTTP test
curl http://SERVER_IP/knetboot/boot.ipxe
curl http://SERVER_IP/knetboot/menus/main.ipxe

# Symlink kontrol
ls -la /var/www/html/knetboot/
```

## Gelecek Özellikler

### v1.0 MVP (Tamamlandı)
- ✅ iPXE boot sistemi
- ✅ Basit web UI
- ✅ Manual image ekleme
- ✅ Menu generator

### v2.0 (Tamamlandı)
- ✅ Otomatik deployment script
- ✅ Health checks
- ✅ Gerçek zamanlı servis durumları
- ✅ Sudoers passwordless yapılandırma

### v2.1 (Tamamlandı)
- ✅ DHCP Configuration Web UI
- ✅ DHCP Toggle Switch (ON/OFF)
- ✅ Network ayarlarını web'den düzenleme
- ✅ DHCP servisini web'den start/stop
- ✅ URL routing fixes (Flask url_for)

### v2.2 (Tamamlandı)
- ✅ Merkezi system.json configuration
- ✅ TFTP Configuration Web UI
- ✅ TFTP Toggle Switch (ON/OFF)
- ✅ TFTP boot dosyaları listesi
- ✅ NTP Server ayarları (web'den düzenlenebilir)
- ✅ Timezone ayarları (web'den düzenlenebilir)
- ✅ DNS servers configuration
- ✅ Tüm ayarlar merkezi config'den okunuyor

### v2.3 (Tamamlandı)
- ✅ TFTP File Upload Web UI (boot loader upload)
- ✅ File delete functionality (remove uploaded files)
- ✅ HTTP Boot Support (faster alternative to TFTP)
- ✅ Dual protocol display (TFTP + HTTP URLs)
- ✅ Boot file validation (.kpxe, .efi, .pxe, .0, .bin)
- ✅ 10MB max upload limit
- ✅ Secure file handling (secure_filename)
- ✅ DNS Configuration Web UI (primary, secondary, tertiary)
- ✅ DNS validation (IP address format check)
- ✅ NGINX Restart button (dashboard quick action)
- ✅ Safe NGINX control (no stop, only restart)

### Faz 3
- [ ] Boot statistics (grafik)
- [ ] Image download progress bar
- [ ] Multi-server support
- [ ] Automated image download from URL

### Faz 4
- [ ] Autoinstall editor (cloud-init)
- [ ] REST API
- [ ] User authentication
- [ ] Webhook events

## Dokümantasyon

- **📖 Konfigürasyon Rehberi**: [CONFIG-GUIDE.md](CONFIG-GUIDE.md) - Detaylı servis ayarları
- **📝 Deployment Notları**: [DEPLOYMENT-NOTES.md](DEPLOYMENT-NOTES.md) - v2.0 geliştirmeleri
- **🎨 Design Doc**: `/home/bekir/Projects/kapadokya_scripts/DOCS/plans/2025-11-04-knetboot-design.md`
- **⚙️ Config Templates**:
  - [config/dhcpd.conf.template](config/dhcpd.conf.template) - DHCP server
  - [config/nginx.conf.template](config/nginx.conf.template) - NGINX
  - [config/tftpd-hpa.conf.template](config/tftpd-hpa.conf.template) - TFTP

## Lisans

Kapadokya Üniversitesi - İç kullanım için

---

**Son Güncelleme:** 2025-11-05
**Yazar:** Bekir
**Status:** v2.3.0 - Production Ready
