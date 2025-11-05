# Kapadokya NetBoot - Deployment Notes

## Version 2.0 - Improved Deployment Script

### 🎯 Ana Geliştirmeler

#### 1. **Otomatik Flask Kurulumu**
- Python venv her zaman temiz olarak yeniden oluşturuluyor
- Flask, PyYAML, Gunicorn otomatik kurulum
- `app.py` her deployment'ta güncelleniyor (en son versiyon garantisi)

#### 2. **Sudoers İzinleri**
```bash
# /etc/sudoers.d/knetboot-web
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl is-active *
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl status *
```
Flask app artık servis durumlarını görebiliyor ✓

#### 3. **Gelişmiş Health Checks**
- Port dinleme kontrolü (5000, 80, 69)
- Servis durumu testi
- HTTP endpoint testleri
- Otomatik log görüntüleme (hata durumunda)

#### 4. **Network Interface Auto-Detection**
```bash
# Script otomatik tespit ediyor:
enp1s0, ens3, eth0, vio0, etc.
```

### 📦 Kurulum Adımları (10 Steps)

```
[1/10] Paket kurulumu (nginx, python3, dhcp, tftp, net-tools)
[2/10] Dizin yapısı oluşturma
[3/10] Dosya kopyalama + izin düzeltmeleri
[4/10] iPXE bootloader indirme (BIOS + UEFI)
[5/10] Python venv kurulumu (temiz yeniden oluşturma)
[6/10] Flask app oluşturma (her zaman en son versiyon)
[7/10] DHCP yapılandırma (otomatik interface detection)
[8/10] NGINX yapılandırma (proxy + static files)
[9/10] Config dosyaları + symlinks
[10/10] Systemd service + sudoers
```

### 🔧 Düzeltilen Sorunlar

#### Sorun 1: Service Status UNKNOWN
**Sebep:** Flask app systemctl komutunu çalıştıramıyordu (izin hatası)
**Çözüm:**
- Sudoers'a passwordless izin eklendi
- Flask app `sudo systemctl` kullanıyor

#### Sorun 2: Flask App Çalışmıyor
**Sebep:** Venv veya dependencies eksik/bozuk olabiliyordu
**Çözüm:**
- Her deployment'ta venv temiz yeniden oluşturuluyor
- Ownership fix: `chown -R www-data:www-data`

#### Sorun 3: API 404 Error
**Sebep:** Flask app düzgün başlamıyordu
**Çözüm:**
- Servisler başlamadan önce durdurma (clean restart)
- 5 saniye bekleme (initialization için)
- Port listening verification

#### Sorun 4: DHCP Syntax Error - "no option named arch"
**Sebep:** DHCP config'de `option arch` kullanılıyordu ama ISC DHCP bu syntaxı desteklemiyor
**Hata:**
```
/etc/dhcp/dhcpd.conf line 14: no option named arch in space dhcp
    } elsif option arch = 00:07 or option arch = 00:09 {
```
**Çözüm:**
- PXE client architecture detection için `vendor-class-identifier` kullanılıyor
- `substring(option vendor-class-identifier, 0, 20)` ile "PXEClient:Arch:00007" kontrol ediliyor
- UEFI systems: Arch 00007 ve 00009 tespit ediliyor
- BIOS systems: else fallback ile undionly.kpxe

### 🌐 Erişim Bilgileri

Kurulum sonrası:
- **Admin Panel:** http://192.168.122.20/admin/
- **Boot Entry:** http://192.168.122.20/knetboot/boot.ipxe
- **Main Menu:** http://192.168.122.20/knetboot/menus/main.ipxe
- **API Status:** http://192.168.122.20/api/status
- **SSH:** `ssh test@192.168.122.20` (password: 123123!!)

### 📊 Admin Panel Özellikleri

**Dashboard gösteriyor:**
- ✅ **Gerçek zamanlı** servis durumları (DHCP, TFTP, NGINX, Web UI)
- Server IP, Boot URL, DHCP Range bilgileri
- Quick links (boot.ipxe, main menu, API)
- Renkli durum kartları (yeşil=running, kırmızı=failed)

**API Endpoint:**
```bash
curl http://192.168.122.20/api/status
# Yanıt:
{
  "dhcp": "active",
  "tftp": "active",
  "nginx": "active",
  "web": "active"
}
```

### 🚀 Deployment Komutu

```bash
cd /home/bekir/Projects/kapadokya_scripts/knetboot
./deploy-knetboot.sh
```

### ✅ Başarı Kriterleri

Script sonunda göreceksiniz:
```
[8/8] Health Check Summary
  Passed: 5
  Failed: 0

✓ All health checks passed! System is ready.
```

#### Sorun 5: URL Routing - Form POST 404 Error
**Sebep:** Template'lerde hardcoded URL'ler (`action="/dhcp/update"`) kullanılıyordu
**Hata:**
```
Form at http://127.0.0.1:8000/admin/dhcp
POST to /dhcp/update → 404 Not Found
(Should be: /admin/dhcp/update)
```
**Çözüm:**
- Template'lerde `url_for()` kullanıldı:
  - `action="/dhcp/update"` → `action="{{ url_for('dhcp_update') }}"`
  - `href="/dhcp/restart"` → `href="{{ url_for('dhcp_restart') }}"`
  - `href="/"` → `href="{{ url_for('index') }}"`
- Flask PrefixMiddleware ile `/admin` prefix otomatik ekleniyor
- NGINX `X-Forwarded-Prefix: /admin` header'ı gönderiyor

#### Sorun 6: Subprocess "No such file or directory: 'sudo'"
**Sebep:** Flask app (Gunicorn/www-data) kısıtlı PATH ile çalışıyor, `sudo` komutunu bulamıyor
**Hata:**
```
Error writing config: [Errno 2] No such file or directory: 'sudo'
```
**Çözüm:**
- Tüm subprocess çağrılarında absolute path kullanıldı:
  - `['sudo', 'systemctl', ...]` → `['/usr/bin/sudo', '/usr/bin/systemctl', ...]`
  - `['sudo', 'dhcpd', ...]` → `['/usr/bin/sudo', '/usr/sbin/dhcpd', ...]`
  - `['sudo', 'tee', ...]` → `['/usr/bin/sudo', '/usr/bin/tee', ...]`

### 🐛 Troubleshooting

**Flask app çalışmıyor mu?**
```bash
ssh test@192.168.122.20
sudo journalctl -u knetboot-web -f
sudo systemctl status knetboot-web
```

**DHCP çalışmıyor mu?**
```bash
ssh test@192.168.122.20
sudo journalctl -u isc-dhcp-server -n 50
# Interface kontrolü:
ip addr show
```

**Port dinleniyor mu?**
```bash
ssh test@192.168.122.20
sudo netstat -tlnp | grep -E ":(80|5000|69)"
```

### 📝 Test Checklist

Snapshot'tan döndükten sonra:

- [ ] `./deploy-knetboot.sh` çalıştır
- [ ] Health checks geçti mi? (5/5)
- [ ] Admin panel açılıyor mu? http://192.168.122.20/admin/
- [ ] Servis durumları "ACTIVE" mı? (UNKNOWN değil!)
- [ ] API çalışıyor mu? http://192.168.122.20/api/status
- [ ] boot.ipxe görünüyor mu?
- [ ] main.ipxe menüsü çalışıyor mu?

---

### 🎯 Yeni Özellikler (v2.1)

#### DHCP Configuration Web UI
- **DHCP Ayarları Sayfası**: Network, netmask, IP range, gateway, DNS, PXE server ayarları
- **Toggle Switch (ON/OFF)**:
  - Dashboard'da küçük toggle switch (40x20px, yeşil/kırmızı)
  - DHCP config sayfasında büyük toggle switch (60x34px)
  - Gerçek zamanlı servis kontrolü (start/stop)
  - AJAX ile backend iletişimi
- **Navigation Menü**: DHCP linki eklendi (router ikonu)
- **Quick Actions**: Dashboard'da DHCP Configuration butonu (sarı, gear ikonu)

#### API Endpoints
- `GET /dhcp` - DHCP configuration sayfası
- `POST /dhcp/update` - DHCP ayarlarını güncelle
- `GET /dhcp/restart` - DHCP servisini restart et
- `POST /dhcp/toggle` - DHCP servisini aç/kapat (JSON)

### 🎯 Yeni Özellikler (v2.2)

#### Merkezi Configuration System
- **system.json**: Tüm sistem ayarlarını tutan merkezi config dosyası
- Server bilgileri (IP, hostname, timezone, NTP)
- Network ayarları (subnet, gateway, DNS, DHCP range)
- Servis ayarları (DHCP, TFTP, NGINX, Web UI)
- Tüm sayfalar aynı config'i kullanıyor (tutarlı veri)

#### TFTP Configuration Web UI
- **TFTP Ayarları Sayfası**: Root directory, listen address, options
- **Toggle Switch (ON/OFF)**:
  - Dashboard'da küçük toggle switch
  - TFTP config sayfasında büyük toggle switch (60x34px)
  - Gerçek zamanlı servis kontrolü (start/stop)
  - AJAX ile backend iletişimi
- **Boot Dosyaları Listesi**: undionly.kpxe (BIOS), ipxe.efi (UEFI)
- **Navigation Menü**: TFTP linki eklendi (hdd-network ikonu)

#### NTP & Timezone Configuration
- **Settings Sayfası Genişletildi**:
  - Timezone ayarı (Europe/Istanbul)
  - NTP Server (192.168.122.10)
  - NTP Fallback servers (Cloudflare, Google)
  - DNS Primary/Secondary/All servers
- **Düzenlenebilir Form**: NTP ve timezone web'den değiştirilebiliyor
- **Otomatik Uygulama**:
  - `timedatectl set-timezone` ile timezone değişir
  - `/etc/systemd/timesyncd.conf.d/local.conf` ile NTP güncellenir
  - `systemctl restart systemd-timesyncd` ile servis yenilenir

#### API Endpoints (Yeni)
- `GET /tftp` - TFTP configuration sayfası
- `POST /tftp/update` - TFTP ayarlarını güncelle
- `GET /tftp/restart` - TFTP servisini restart et
- `POST /tftp/toggle` - TFTP servisini aç/kapat (JSON)
- `POST /settings/time` - NTP ve timezone ayarlarını güncelle

#### Bug Fixes (v2.2.1)
- **Server Name Fix**: Settings sayfasında server name artık `hostnamectl`'den dinamik olarak çekiliyor (sabit değer yerine)
- **TFTP Address Fix**: TFTP config sayfasında address parse edilirken port kısmı (`:69`) kaldırılıyor, update sırasında otomatik ekleniyor
- **TFTP Port Bug**: `TFTP_ADDRESS` field'ında port duplicate sorunu düzeltildi (`:69:69` hatası)
- **TFTP Address Edge Case**: `:69` formatındaki address'ler için fallback (`0.0.0.0`) eklendi
- **system.json Permissions**: DHCP config update çalışmıyordu - system.json ownership www-data:www-data olarak düzeltildi
- **DHCP Range Validation**: DHCP range end IP, start IP'den küçükse hata veriyor (IP validation eklendi)

#### Deployment Script Updates (v2.2.1)
- **system.json Creation**: Deployment script artık system.json'u otomatik oluşturuyor
- **Automatic Ownership**: system.json dosyası www-data:www-data ownership ile oluşturuluyor (write access için)
- **Complete Configuration**: Tüm server, network, services, paths bilgileri deployment sırasında dolduruluyor

#### Yeni Özellikler (v2.3)

##### TFTP File Upload & Management
- **File Upload Form**: TFTP configuration sayfasında boot dosyası upload formu
- **Allowed Extensions**: .kpxe, .efi, .pxe, .0, .bin dosyaları (10MB max)
- **File Validation**: Secure filename + extension checking
- **Delete Functionality**: Her dosya için silme butonu (confirmation ile)
- **Sudoers Permissions**: www-data için /srv/tftp dosya yönetimi izinleri

##### HTTP Boot Support (TFTP Alternative)
- **Faster Protocol**: HTTP (TCP/80) ile boot dosyalarını sunma (TFTP'den çok daha hızlı)
- **Dual Protocol Display**: Her boot dosyası için hem TFTP hem HTTP URL'leri gösteriliyor
- **Flask Endpoint**: `/boot/http/<filename>` route ile dosya sunma
- **NGINX Proxy**: `/boot/http/` location ile Flask'a proxy
- **Always Available**: HTTP boot her zaman aktif (TFTP toggle'dan bağımsız)
- **Same Files**: TFTP ve HTTP aynı dizinden (`/srv/tftp`) dosya sunuyor

##### DNS Configuration Web UI
- **Editable DNS Settings**: Settings sayfasında DNS Primary, Secondary, Tertiary ayarları
- **IP Validation**: DNS IP adresleri için format kontrolü
- **system.json Update**: DNS ayarları merkezi config'e kaydediliyor
- **DHCP Integration**: DNS değişiklikleri DHCP config güncellenerek uygulanıyor
- **Flash Messages**: Başarı/hata mesajları ile kullanıcı bilgilendirmesi

##### NGINX Restart Control
- **Dashboard Restart Button**: Services Status kartında NGINX için restart butonu
- **Safe Operation**: NGINX stop fonksiyonu yok (web arayüzünü kilitlememek için)
- **Warning Messages**: Restart işlemi için kullanıcı onayı
- **Auto Reload**: Restart sonrası sayfa otomatik yenileniyor
- **Spinner UI**: İşlem sırasında loading indicator

##### API Endpoints (Yeni)
- `POST /tftp/upload` - Boot dosyası upload (multipart/form-data)
- `POST /tftp/delete/<filename>` - Boot dosyası silme
- `GET /boot/http/<filename>` - HTTP üzerinden boot dosyası sunma
- `POST /settings/dns` - DNS ayarlarını güncelle (primary, secondary, tertiary)
- `POST /nginx/restart` - NGINX servisini restart et

##### Deployment Script Updates (v2.3)
- **Sudoers Enhancement**: TFTP boot dosyası yönetimi için izinler eklendi
  - `/usr/bin/cp /tmp/* /srv/tftp/*`
  - `/usr/bin/chmod 644 /srv/tftp/*`
  - `/usr/bin/rm -f /srv/tftp/*`
  - `/usr/bin/systemctl restart nginx`
- **NGINX Template**: HTTP boot location eklendi (`/boot/http/`)

##### Usage Examples
**HTTP Boot (iPXE):**
```
# Traditional TFTP boot (slower)
chain tftp://192.168.122.20/undionly.kpxe

# HTTP boot (faster, recommended!)
chain http://192.168.122.20/boot/http/undionly.kpxe
```

**Upload via Web UI:**
1. Navigate to http://SERVER_IP/admin/tftp
2. Scroll to "Upload Boot File" section
3. Choose .kpxe or .efi file (max 10MB)
4. Click "Upload File"
5. File will appear in boot files list with HTTP + TFTP URLs

**Delete via Web UI:**
1. Find file in boot files list
2. Click red trash icon
3. Confirm deletion

---

**Son Güncelleme:** 2025-11-05
**Versiyon:** 2.3.0
**Durum:** Full Web Management + HTTP Boot + File Upload Complete
