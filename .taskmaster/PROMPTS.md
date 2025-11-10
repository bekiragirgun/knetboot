# knetboot - Claude Task Master Prompt Rehberi

Bu dokümان, knetboot projesi için Claude ile çalışırken kullanılacak yapılandırılmış promptları içerir.

## 📋 İçindekiler

1. [Proje Başlatma](#proje-başlatma)
2. [Özellik Geliştirme](#özellik-geliştirme)
3. [Bug Fix](#bug-fix)
4. [Dokümantasyon](#dokümantasyon)
5. [Test ve Kalite](#test-ve-kalite)
6. [Deployment](#deployment)
7. [Araştırma](#araştırma)

---

## 🚀 Proje Başlatma

### Yeni Task Listesi Oluşturma
```
knetboot projesinde yeni bir özellik eklemek istiyorum. Şu özellikleri ekle:
- [Özellik açıklaması]
- [Gereksinimler]
- [Bağımlılıklar]

Bunu implementasyonu için task listesi oluştur ve alt görevlere böl.
```

### Mevcut Kodu Analiz Etme
```
knetboot projesinin [modül_adı] modülünü analiz et:
- Mimari yapı
- Kullanılan teknolojiler
- İyileştirme önerileri
- Potansiyel sorunlar

Detaylı bir rapor hazırla.
```

---

## ⚡ Özellik Geliştirme

### Web UI Özelliği
```
knetboot web UI'ına yeni bir sayfa/özellik ekle:

**Özellik**: [Özellik adı]
**Lokasyon**: web/templates/[sayfa].html
**Backend**: web/app.py - yeni route ekle
**Gereksinimler**:
- [ ] HTML template oluştur
- [ ] Flask route ekle
- [ ] API endpoint(ler) ekle
- [ ] Frontend JavaScript/CSS
- [ ] Hata yönetimi
- [ ] Dokümantasyon güncelle

**Referans**: Mevcut [benzer_sayfa] sayfasını örnek al
**Design**: Bootstrap 5, mevcut tema ile tutarlı
```

### Backend API Endpoint
```
knetboot Flask uygulamasına yeni API endpoint ekle:

**Endpoint**: /admin/api/[resource]/[action]
**Method**: [GET/POST/PUT/DELETE]
**İşlev**: [Ne yapacak]
**Input**: [Parametreler]
**Output**: [JSON response format]

**Task Listesi**:
1. Route tanımla (web/app.py)
2. Business logic yaz
3. Hata yönetimi ekle (try/except)
4. JSON response formatı belirle
5. Logging ekle
6. API test et (curl örnekleri)
7. Dokümantasyon yaz

**Referans**: /admin/api/status endpoint'i örnek al
```

### Autoinstall Yapılandırması
```
knetboot için yeni bir autoinstall profili oluştur:

**OS/Distro**: [Ubuntu 24.04 / Debian 12 / etc.]
**Tip**: [Server / Desktop / Minimal]
**Özellikler**:
- Disk layout: [LVM / Standard / etc.]
- Packages: [Liste]
- Network: [DHCP / Static]
- Post-install: [Komutlar]

**Lokasyon**: config/autoinstall/[distro]-[variant]/
**Dosyalar**:
- user-data (cloud-init config)
- meta-data
- README.md (kullanım kılavuzu)

**Referans**: config/autoinstall/ubuntu-server/ dizinini örnek al
```

### iPXE Menü Özelliği
```
knetboot iPXE menülerine yeni boot seçeneği ekle:

**Menü**: [main / tools / ubuntu / etc.]
**Boot Entry**: [Adı]
**Kernel**: [Path ve parametreler]
**Initrd**: [Path]
**Boot Args**: [Kernel boot arguments]

**Task Listesi**:
1. Menü dosyasını düzenle (config/menus/[menu].ipxe)
2. Kernel/initrd dosyalarını assets/ altına kopyala
3. HTTP erişim testi yap
4. Boot testi yap (VM)
5. Dokümantasyon güncelle

**Test**: Libvirt/QEMU VM ile PXE boot testi
```

---

## 🐛 Bug Fix

### Bug Raporlama ve Fix
```
knetboot'ta bir hata buldum:

**Sorun**: [Hatanın açıklaması]
**Lokasyon**: [Dosya:satır veya modül]
**Reprodüksiyon**:
1. [Adım 1]
2. [Adım 2]
3. [Hata oluşuyor]

**Beklenen Davranış**: [Ne olmalı]
**Gerçek Davranış**: [Ne oluyor]
**Loglar**: [Varsa log çıktıları]

**Fix Task Listesi**:
1. Hatayı repro et
2. Root cause analizi yap
3. Fix uygula
4. Test et
5. Regression test yap
6. Commit ve push

**Öncelik**: [Düşük / Orta / Yüksek / Kritik]
```

### Service/Systemd Sorunları
```
knetboot servisinde sorun var:

**Servis**: [knetboot-web / isc-dhcp-server / nginx / tftpd-hpa]
**Sorun**: [Başlamıyor / Crash oluyor / Yavaş / etc.]
**Loglar**: journalctl -u [servis] çıktısı:
[Log çıktısı]

**Debug Adımları**:
1. Service status kontrol
2. Config dosyası validasyonu
3. Port çakışması kontrolü
4. Disk/memory kullanımı
5. Dependency check

Sorunu tespit et ve düzelt.
```

---

## 📚 Dokümantasyon

### README Güncelleme
```
knetboot README.md dosyasını güncelle:

**Değişiklikler**:
- [Yeni özellik ekle]
- [Versiyon güncelle]
- [Yeni bölüm ekle]

**Bölümler**:
- Özellikler listesi
- Kurulum adımları
- Kullanım örnekleri
- Versiyon geçmişi
- Dokümantasyon linkleri

**Format**: Markdown, emoji kullan, net ve açıklayıcı ol
**Referans**: Mevcut README.md stilini koru
```

### API Dokümantasyonu
```
knetboot API dokümantasyonu oluştur/güncelle:

**Endpoint**: /admin/api/[endpoint]
**Format**:
- Request method ve URL
- Request parameters (query, body)
- Response format (JSON schema)
- Status codes (200, 400, 404, 500)
- cURL örnekleri
- JavaScript fetch örnekleri

**Lokasyon**: docs/API.md veya README.md içinde

Tüm /admin/api/* endpoint'lerini dokümante et.
```

### Kullanım Kılavuzu
```
knetboot için [özellik] kullanım kılavuzu yaz:

**Kapsam**: [Özelliğin adı ve amacı]
**Hedef Kitle**: [Yeni kullanıcı / Admin / Developer]

**İçerik**:
1. Giriş ve amaç
2. Ön gereksinimler
3. Adım adım kurulum
4. Yapılandırma seçenekleri
5. Kullanım örnekleri
6. Sorun giderme
7. Sık sorulan sorular

**Format**: Markdown, ekran görüntüleri ekle (opsiyonel)
**Lokasyon**: docs/[feature]-guide.md veya config/[feature]/README.md
```

---

## ✅ Test ve Kalite

### Manuel Test Senaryosu
```
knetboot için [özellik] test senaryosu oluştur:

**Test Edilen Özellik**: [Özellik adı]
**Test Tipi**: [Fonksiyonel / Integration / End-to-End]

**Test Senaryoları**:
1. **[Senaryo 1]**
   - Ön koşullar: [...]
   - Adımlar: [...]
   - Beklenen sonuç: [...]

2. **[Senaryo 2]**
   - ...

**Test Ortamı**:
- OS: Ubuntu 24.04 Server
- Network: Libvirt default (192.168.122.0/24)
- VM: PXE boot client

Test senaryolarını çalıştır ve sonuçları raporla.
```

### Güvenlik Analizi
```
knetboot için güvenlik analizi yap:

**Kapsam**: [Tüm sistem / Web UI / API / Network boot]

**Kontrol Listesi**:
- [ ] Input validasyonu
- [ ] SQL injection koruması
- [ ] XSS koruması
- [ ] CSRF token kontrolü
- [ ] Kimlik doğrulama (varsa)
- [ ] Yetkilendirme
- [ ] Hassas bilgi maskeleme
- [ ] HTTPS/TLS kullanımı
- [ ] Güvenli dosya upload
- [ ] Log güvenliği

Bulguları raporla ve öneriler sun.
```

### Performans Testi
```
knetboot performans testi yap:

**Test Alanları**:
- PXE boot süresi (TFTP vs HTTP)
- Web UI response time
- API endpoint hızı
- Concurrent client desteği
- Network bandwidth kullanımı

**Metrikler**:
- Boot time: [ms/s]
- API latency: [ms]
- Throughput: [MB/s]
- Concurrent connections: [sayı]

**Araçlar**: curl, ab (Apache Bench), iperf3, time

Sonuçları benchmark tablosu olarak raporla.
```

---

## 🚀 Deployment

### Production Deployment
```
knetboot'u production ortamına deploy et:

**Ortam**: [Sunucu IP/hostname]
**Versiyon**: [v2.4.0]

**Deployment Checklist**:
- [ ] Backup al (config, database)
- [ ] deploy-knetboot.sh güncelle
- [ ] Git pull/clone
- [ ] Config dosyalarını güncelle
  - [ ] Server IP
  - [ ] Network settings
  - [ ] DHCP range
- [ ] Servisleri yeniden başlat
- [ ] Health check yap
- [ ] Test boot yap (PXE client)
- [ ] Logları kontrol et
- [ ] Dokümantasyonu güncelle

**Rollback Plan**: [Geri alma adımları]
```

### Versiyon Yükseltme
```
knetboot versiyonunu [v2.3.0] → [v2.4.0] yükselt:

**Değişiklikler**:
- [Yeni özellikler]
- [Bug fix'ler]
- [Breaking changes]

**Migration Adımları**:
1. Backup config files
2. Git checkout/pull yeni versiyon
3. Database migration (varsa)
4. Config migration
5. Dependency update
6. Test
7. Deploy

**Dokümantasyon**:
- README version bump
- CHANGELOG güncelle
- Migration guide yaz (breaking changes varsa)
```

---

## 🔍 Araştırma

### Teknoloji Araştırması
```
[Teknoloji/özellik] araştır ve knetboot'a entegrasyon için öneri sun:

**Teknoloji**: [Teknoloji adı]
**Amaç**: [Neden araştırıyoruz]
**Kapsam**: [Hangi problemi çözer]

**Araştırma Soruları**:
- Nasıl çalışır?
- Avantajları nedir?
- Dezavantajları nedir?
- knetboot ile uyumu nasıl?
- Alternatifler neler?
- Implementasyon karmaşıklığı?
- Dokümantasyon kalitesi?

**Çıktı**:
- Özet rapor
- Entegrasyon önerisi
- POC kodu (opsiyonel)
- İmplementasyon tahmini (süre/karmaşıklık)

**Kaynaklar**: Resmi dokümantasyon, GitHub, blog yazıları, Stack Overflow
```

### Best Practices Araştırması
```
[Alan] için en iyi uygulamaları araştır ve knetboot'a uygula:

**Alan**: [Flask security / iPXE optimization / PXE boot / etc.]

**Araştırma Konuları**:
- Industry standards
- Security best practices
- Performance optimization
- Error handling patterns
- Logging strategies

**Çıktı**:
- Best practices listesi
- Mevcut kod analizi (uyum durumu)
- İyileştirme önerileri
- Implementasyon planı

Bulguları uygula ve dokümante et.
```

---

## 🎯 Proje-Spesifik Promptlar

### Ubuntu Autoinstall Profili Ekleme
```
knetboot'a yeni Ubuntu autoinstall profili ekle:

**Profil**: [Ubuntu 24.04 Custom / Debian 12 / etc.]
**Base**: config/autoinstall/ubuntu-server/ (referans)

**Özelleştirmeler**:
- Hostname: [...]
- Username/Password: [...]
- Packages: [...]
- Network: [...]
- Timezone: [...]
- Locale: [...]
- Post-install commands: [...]

**Görevler**:
1. Yeni dizin oluştur: config/autoinstall/[profile-name]/
2. user-data dosyası oluştur (cloud-init YAML)
3. meta-data dosyası oluştur
4. README.md yaz (profil özel)
5. iPXE menu entry ekle
6. Test et (VM ile)
7. Dokümantasyon güncelle

**Validasyon**: YAML syntax check, boot test
```

### DHCP Konfigürasyonu
```
knetboot DHCP yapılandırmasını güncelle:

**Değişiklikler**:
- Network: [192.168.x.0/24]
- DHCP Range: [Start - End]
- Gateway: [IP]
- DNS: [IP listesi]
- Lease time: [Süre]
- Static reservations: [MAC → IP mapping]

**İşlemler**:
1. config/dhcpd.conf.template düzenle
2. Web UI'dan güncelle (varsa)
3. Syntax check: dhcpd -t -cf /etc/dhcp/dhcpd.conf
4. Service restart: systemctl restart isc-dhcp-server
5. Test: DHCP client ile IP al
6. Log kontrol: journalctl -u isc-dhcp-server

**Dokümantasyon**: CONFIG-GUIDE.md güncelle
```

### Web UI Component Ekleme
```
knetboot web UI'ya yeni component/widget ekle:

**Component**: [Component adı ve amacı]
**Sayfa**: [Dashboard / DHCP Config / etc.]
**Tip**: [Card / Table / Form / Chart]

**Gereksinimler**:
- HTML: web/templates/[page].html
- CSS: web/static/css/style.css (custom styles)
- JavaScript: web/static/js/[script].js (interactivity)
- Backend: web/app.py (data endpoint)

**Design**:
- Bootstrap 5 components kullan
- Responsive design (mobile-friendly)
- Mevcut tema renkleri (#2c3e50, #3498db)
- Icon: Font Awesome

**Örnek**: Dashboard'daki service status cards'ı referans al
```

---

## 💡 Prompt Yazma İpuçları

### Etkili Prompt Yapısı

1. **Bağlam Ver**:
   - Proje: knetboot
   - Modül/dosya: [path]
   - İlgili teknoloji: Flask, iPXE, cloud-init, etc.

2. **Net Hedef Belirt**:
   - Ne yapılacak: [Özellik ekle / Bug fix / Refactor]
   - Neden: [Amaç ve fayda]

3. **Gereksinimler Listesi**:
   - Fonksiyonel gereksinimler
   - Teknik gereksinimler
   - Kısıtlamalar

4. **Referans Ver**:
   - Benzer kod: [Dosya:satır]
   - Dokümantasyon: [Link veya dosya]
   - Örnek: [Kullanım örneği]

5. **Başarı Kriteri**:
   - Nasıl test edilecek
   - Beklenen çıktı
   - Kabul kriterleri

### Prompt Örnekleri

**❌ Kötü Prompt**:
```
Web UI'ya bir şey ekle.
```

**✅ İyi Prompt**:
```
knetboot web UI'sına boot statistics sayfası ekle:

**Lokasyon**: web/templates/statistics.html
**Backend**: web/app.py - yeni /admin/statistics route
**Veri**: Boot loglarından istatistik topla (successful/failed boots)
**Görselleştirme**: Chart.js ile grafik (line/bar chart)
**Referans**: Dashboard sayfası layoutunu örnek al

Task listesi oluştur ve implement et.
```

---

## 📝 Notlar

- Her prompt sonunda "Task listesi oluştur" veya "Implementasyona başla" belirt
- Büyük işleri alt görevlere böl
- Her adımı test et
- Dokümantasyonu güncellemeyi unutma
- Git commit mesajlarını anlamlı yaz
- Code review yap (kendin veya Claude'a incelet)

---

**Versiyon**: 1.0.0
**Son Güncelleme**: 2025-11-08
**Yazar**: Bekir
**Proje**: knetboot v2.4.0
