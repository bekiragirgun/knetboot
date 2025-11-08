# Ubuntu 24.04 Autoinstall Configurations

Bu dizin, Ubuntu 24.04 LTS Server ve Desktop için otomatik kurulum yapılandırma dosyalarını içerir. Cloud-init ve Subiquity teknolojileri kullanılarak tamamen katılımsız kurulum sağlar.

## İçindekiler

- `ubuntu-server/` - Ubuntu 24.04 LTS Server otomatik kurulum
- `ubuntu-desktop/` - Ubuntu 24.04 LTS Desktop otomatik kurulum

## Dosya Yapısı

Her dizin şu dosyaları içerir:
- **user-data**: Autoinstall yapılandırma dosyası (YAML formatı)
- **meta-data**: Cloud-init metadata dosyası

## Özellikler

### Ubuntu Server
- Minimal kurulum (ubuntu-server-minimal)
- Önceden yüklenmiş paketler: git, curl, wget, vim, nano, htop, build-essential
- PowerShell snap paketi
- SSH server (varsayılan olarak aktif)
- LVM storage layout
- Otomatik güvenlik güncellemeleri
- Kurulum sonrası otomatik yeniden başlatma

### Ubuntu Desktop
- Minimal desktop kurulum (ubuntu-desktop-minimal)
- HWE kernel (daha iyi donanım desteği)
- Otomatik codec ve driver kurulumu
- LVM storage layout
- Otomatik güvenlik güncellemeleri
- Kurulum sonrası otomatik yeniden başlatma

## Varsayılan Kimlik Bilgileri

**⚠️ GÜVENLİK UYARISI: İlk girişten sonra şifreyi değiştirin!**

- **Kullanıcı adı**: ubuntu
- **Şifre**: ubuntu
- **Root şifresi**: ubuntu

## PXE Boot ile Kullanım

### 1. HTTP Sunucusu Hazırlama

Autoinstall dosyalarını HTTP üzerinden erişilebilir hale getirin:

```bash
# knetboot için symlink oluştur
sudo ln -s /opt/knetboot/config/autoinstall /var/www/html/knetboot/autoinstall

# NGINX yeniden başlat
sudo systemctl restart nginx
```

### 2. iPXE Menü Yapılandırması

iPXE menülerinize autoinstall parametrelerini ekleyin. Örnek menü:

**Ubuntu Server Autoinstall:**
```ipxe
#!ipxe
kernel http://SERVER_IP/knetboot/assets/ubuntu/24.04/server/vmlinuz \
    ip=dhcp \
    url=http://SERVER_IP/ubuntu-24.04-live-server-amd64.iso \
    autoinstall \
    ds=nocloud-net;s=http://SERVER_IP/knetboot/autoinstall/ubuntu-server/

initrd http://SERVER_IP/knetboot/assets/ubuntu/24.04/server/initrd
boot
```

**Ubuntu Desktop Autoinstall:**
```ipxe
#!ipxe
kernel http://SERVER_IP/knetboot/assets/ubuntu/24.04/desktop/vmlinuz \
    ip=dhcp \
    url=http://SERVER_IP/ubuntu-24.04-desktop-amd64.iso \
    autoinstall \
    ds=nocloud-net;s=http://SERVER_IP/knetboot/autoinstall/ubuntu-desktop/

initrd http://SERVER_IP/knetboot/assets/ubuntu/24.04/desktop/initrd
boot
```

**Önemli Parametreler:**
- `autoinstall`: Otomatik kurulumu etkinleştirir
- `ds=nocloud-net;s=URL`: Cloud-init data source URL'i
  - URL, user-data ve meta-data dosyalarının bulunduğu dizini işaret etmelidir
  - URL sonunda `/` olmalıdır

### 3. Ubuntu ISO Görüntülerini Hazırlama

Ubuntu ISO dosyalarını HTTP sunucunuza kopyalayın:

```bash
# ISO dosyalarını indir
cd /var/www/html/
wget https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso
wget https://releases.ubuntu.com/24.04/ubuntu-24.04-desktop-amd64.iso

# Kernel ve initrd dosyalarını çıkart
mkdir -p /opt/knetboot/assets/ubuntu/24.04/{server,desktop}

# Server
sudo mount -o loop ubuntu-24.04-live-server-amd64.iso /mnt
sudo cp /mnt/casper/vmlinuz /opt/knetboot/assets/ubuntu/24.04/server/
sudo cp /mnt/casper/initrd /opt/knetboot/assets/ubuntu/24.04/server/
sudo umount /mnt

# Desktop
sudo mount -o loop ubuntu-24.04-desktop-amd64.iso /mnt
sudo cp /mnt/casper/vmlinuz /opt/knetboot/assets/ubuntu/24.04/desktop/
sudo cp /mnt/casper/initrd /opt/knetboot/assets/ubuntu/24.04/desktop/
sudo umount /mnt
```

## Özelleştirme

### Şifre Değiştirme

Yeni şifre hash'i oluşturmak için:

```bash
openssl passwd -6 -salt xyz YourPasswordHere
```

Çıktı hash'i user-data dosyasındaki `identity.password` alanına kopyalayın.

### Ağ Yapılandırması

Network ayarlarını değiştirmek için user-data dosyasındaki `network` bölümünü düzenleyin:

```yaml
network:
  version: 2
  ethernets:
    ens33:
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
```

### Ek Paketler

Server için ek paketler eklemek:

```yaml
packages:
  - git
  - curl
  - docker.io
  - python3-pip
  - your-package-here
```

### Timezone

Timezone'u değiştirmek için:

```yaml
timezone: Europe/Istanbul  # veya Asia/Shanghai, America/New_York, vb.
```

### Hostname

Hostname'i değiştirmek için:

```yaml
identity:
  hostname: your-hostname-here
```

### Late Commands

Kurulum sonrası komutlar eklemek için `late-commands` bölümünü kullanın:

```yaml
late-commands:
  - curtin in-target --target /target -- apt install -y docker.io
  - curtin in-target --target /target -- systemctl enable docker
  - reboot
```

## Teknik Gereksinimler

- **UEFI Mode**: Autoinstall UEFI modunda çalışır (BIOS legacy mode desteklenmez)
- **RAM**: En az 4GB (Desktop için 8GB önerilir)
- **Disk**: En az 25GB (Desktop için 50GB önerilir)
- **Network**: DHCP veya statik IP yapılandırması

## Kurulum Süresi

- **Server**: ~10-15 dakika
- **Desktop**: ~20-30 dakika

Kurulum tamamlandığında sistem otomatik olarak yeniden başlar.

## Sorun Giderme

### Autoinstall başlamıyor

1. Boot parametrelerini kontrol edin (`autoinstall` ve `ds=nocloud-net` parametreleri olmalı)
2. user-data ve meta-data dosyalarının HTTP üzerinden erişilebilir olduğunu kontrol edin:
   ```bash
   curl http://SERVER_IP/knetboot/autoinstall/ubuntu-server/user-data
   curl http://SERVER_IP/knetboot/autoinstall/ubuntu-server/meta-data
   ```

### YAML sözdizimi hataları

user-data dosyasını YAML linter ile kontrol edin:

```bash
python3 -c 'import yaml, sys; yaml.safe_load(sys.stdin)' < user-data
```

### Eski donanımda takılma

Bazı eski bilgisayarlarda kurulum takılabilir. Bu durumda:
- UEFI ayarlarını kontrol edin
- Secure Boot'u devre dışı bırakın
- Farklı bir makine deneyin

## Referanslar

- [Ubuntu Autoinstall Dokumentasyonu](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html)
- [Cloud-init Dokumentasyonu](https://cloudinit.readthedocs.io/)
- [Kaynak Proje](https://github.com/Kikyo-chan/Autoinstall-Ubuntu24.04-LTS-Server-and-Desktop)

## Lisans

Bu yapılandırmalar Kapadokya Üniversitesi için uyarlanmıştır.
Orijinal kaynak: https://github.com/Kikyo-chan/Autoinstall-Ubuntu24.04-LTS-Server-and-Desktop

---

**Son Güncelleme**: 2025-11-08
**Versiyon**: 1.0.0
