# Product Requirements Document - Boot Statistics Dashboard

**Proje**: knetboot
**Özellik**: Boot Statistics Dashboard
**Versiyon**: v2.5.0
**Yazar**: Bekir
**Tarih**: 2025-11-08
**Durum**: Example / Draft

---

## 📋 Özet

**Tek Cümle Özet**: knetboot admin paneline boot istatistiklerini görselleştiren bir dashboard ekle, böylece yöneticiler PXE boot başarı oranlarını ve kullanım trendlerini takip edebilsin.

**Problem**: Şu anda hangi image'lerin ne kadar kullanıldığı, boot başarı oranları, en çok tercih edilen OS'ler gibi metrikleri göremiyoruz. Troubleshooting zor, kullanım trendleri bilinmiyor.

**Çözüm**: DHCP ve NGINX loglarını parse ederek boot istatistiklerini toplayan ve Chart.js ile görselleştiren bir dashboard sayfası.

**Başarı Metrikleri**:
- Boot success rate görünür: %95+
- Chart load time: < 1s
- Günlük/haftalık/aylık trendler görüntülenebilir
- En popüler 5 image listelenebilir

---

## 🎯 Hedefler ve Hedef Kitle

### Hedefler
1. Boot istatistiklerini real-time görselleştirmek
2. Troubleshooting için insight sağlamak (hangi image'lerde sorun var)
3. Capacity planning için veri toplamak (hangi OS'ler daha çok kullanılıyor)

### Hedef Kullanıcılar
- **Birincil**: Sistem yöneticileri (knetboot admin'leri)
- **İkincil**: IT managers (rapor için)

### Kullanım Senaryoları
1. **Yönetici, günlük boot sayısını görmek istiyor**: Dashboard açar, bugünün boot count'unu görür
2. **Sorun analizi**: Hangi image'de çok failed boot var diye kontrol eder
3. **Trend analizi**: Son 30 günde hangi OS daha popüler olmuş bakar

---

## 📐 Fonksiyonel Gereksinimler

### Temel Özellikler (Must Have)
- [ ] **Boot Count Chart**: Son 7 gün/30 günde günlük boot sayısı (line chart)
  - Input: DHCP logs, NGINX logs
  - Output: Chart.js line chart
  - Filter: Zaman aralığı (7d, 30d, 90d)

- [ ] **Success/Failure Breakdown**: Başarılı vs başarısız bootlar (pie chart)
  - Success: HTTP 200 responses
  - Failure: HTTP 404, 500 errors

- [ ] **Top Images**: En çok boot edilen 5 image (bar chart)
  - Data: NGINX access log'dan /knetboot/assets/* istekleri

- [ ] **Recent Boots**: Son 10 boot activity (table)
  - Timestamp, Client IP, Image, Status

### İkincil Özellikler (Should Have)
- [ ] **Client Stats**: Kaç unique client boot yaptı
- [ ] **Download Stats**: Total bandwidth kullanımı (GB)
- [ ] **Export**: CSV/JSON export özelliği

### Gelecek Özellikler (Nice to Have)
- [ ] Real-time updates (WebSocket)
- [ ] Alert system (boot failure threshold)
- [ ] Historical comparison (bu ay vs geçen ay)

---

## 🏗️ Teknik Gereksinimler

### Mimari
- **Frontend**: HTML + Bootstrap 5 + Chart.js
- **Backend**: Flask route (/admin/statistics)
- **Data Source**: Log parsing (journalctl, nginx logs)
- **Storage**: SQLite database (stats cache)

### Teknoloji Stack
- **Diller**: Python 3.x, JavaScript ES6+
- **Framework**: Flask
- **Libraries**:
  - Chart.js 4.x (charting)
  - Moment.js (date handling)
  - pandas (log parsing - optional)
- **Tools**: journalctl, nginx access.log

### Veri Modeli
```python
# SQLite schema
CREATE TABLE boot_stats (
    id INTEGER PRIMARY KEY,
    timestamp DATETIME,
    client_ip VARCHAR(15),
    image_path VARCHAR(255),
    image_name VARCHAR(100),
    status_code INTEGER,
    bytes_transferred INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### API Endpoints
1. **GET /admin/api/statistics/boots**
   - Query params: `period=7d|30d|90d`
   - Response:
   ```json
   {
     "data": [
       {"date": "2025-11-01", "count": 15},
       {"date": "2025-11-02", "count": 22}
     ],
     "status": "success"
   }
   ```

2. **GET /admin/api/statistics/top-images**
   - Response:
   ```json
   {
     "data": [
       {"image": "Ubuntu 24.04 Server", "boots": 45},
       {"image": "Debian 12 Desktop", "boots": 32}
     ]
   }
   ```

3. **GET /admin/api/statistics/recent**
   - Limit: 10
   - Response: Latest boot records

---

## 🎨 UI/UX Tasarım

### Sayfa Yapısı
```
/admin/statistics/
├── Header (Stats Dashboard)
├── Summary Cards Row
│   ├── Total Boots Today
│   ├── Success Rate
│   └── Active Clients
├── Charts Row
│   ├── Boot Trend (Line Chart)
│   └── Success/Failure (Pie Chart)
├── Top Images (Bar Chart)
└── Recent Activity (Table)
```

### Wireframe
```
+------------------------------------------------+
|  Statistics Dashboard                          |
+------------------------------------------------+
| [Total: 152] [Success: 98%] [Clients: 45]     |
+------------------------------------------------+
|  Boot Trend (7d/30d/90d)                       |
|  [Line Chart]              [Pie Chart]         |
|                             Success/Fail       |
+------------------------------------------------+
|  Top 5 Images                                  |
|  [Bar Chart]                                   |
+------------------------------------------------+
|  Recent Boots                                  |
|  Timestamp | Client IP | Image | Status        |
|  10:23 AM | 192.168... | Ubuntu | Success      |
+------------------------------------------------+
```

### UI Components
- Bootstrap 5 Cards (summary stats)
- Chart.js charts (responsive)
- DataTables (recent boots table)
- Date range picker (period selector)

---

## 🔐 Güvenlik Gereksinimleri

- [ ] Admin authentication (currently no auth, plan for future)
- [ ] SQL injection protection (parameterized queries)
- [ ] XSS protection (escape user data)
- [ ] Rate limiting (API endpoints)

---

## ⚡ Performans Gereksinimleri

- **Chart Load**: < 1s (with 1000 data points)
- **API Response**: < 200ms
- **Log Parsing**: Background job (cron), not real-time
- **Database**: Index on timestamp, client_ip

---

## 🧪 Test Gereksinimleri

### Test Senaryoları
1. **Happy Path**: Dashboard açılır, chartlar yüklenir, data görünür
2. **Empty Data**: Yeni kurulum, hiç boot yok → "No data" mesajı
3. **Large Dataset**: 10,000 boot record ile performance test

### Kabul Kriterleri
- [ ] Chartlar doğru data gösteriyor
- [ ] Period filter çalışıyor (7d, 30d, 90d)
- [ ] Mobile responsive
- [ ] Browser compat (Chrome, Firefox, Edge)

---

## 📦 Bağımlılıklar

### Teknik Bağımlılıklar
- Python >= 3.8
- Flask >= 2.0
- Chart.js >= 4.0
- SQLite3

### Özellik Bağımlılıklar
- DHCP server running (logs available)
- NGINX running (access logs)
- journalctl access (systemd logs)

---

## 🗺️ Implementasyon Planı

### Faz 1: Backend (3 gün)
- [ ] SQLite database oluştur
- [ ] Log parser script yaz (NGINX access.log)
- [ ] Cron job setup (hourly log parsing)
- [ ] API endpoints (/admin/api/statistics/*)

### Faz 2: Frontend (2 gün)
- [ ] statistics.html template
- [ ] Chart.js integration
- [ ] JavaScript data fetching
- [ ] CSS styling

### Faz 3: Integration (1 gün)
- [ ] API-Frontend integration
- [ ] Error handling
- [ ] Loading states

### Faz 4: Testing & Docs (1 gün)
- [ ] Manual testing
- [ ] Performance testing
- [ ] Documentation

**Toplam Süre**: ~7 gün (1 hafta)

---

## 🚧 Riskler ve Kısıtlamalar

### Riskler
1. **Log Parsing Complexity**: NGINX log format değişirse parser bozulabilir
   - Mitigation: Regex patterns flexible yap, unit test ekle

2. **Performance**: Çok büyük log dosyaları yavaşlatabilir
   - Mitigation: Log rotation, incremental parsing

### Kısıtlamalar
- Real-time değil (hourly update)
- Authentication yok (gelecek versiyonda)

---

## 📊 Başarı Metrikleri ve KPI'lar

- **Kullanım**: Yöneticiler günde 1+ kez dashboard'a bakıyor
- **Insight**: Boot failure rate %5'in altına düşüyor (erken tespit)
- **Performance**: Chart load < 1s

---

## 🔄 Gelecek İyileştirmeler

### v2.6
- [ ] Real-time WebSocket updates
- [ ] Alert notifications (Slack/email)
- [ ] Historical comparison

### v3.0
- [ ] Predictive analytics (ML)
- [ ] Custom report builder
- [ ] Multi-server aggregation

---

## 📚 Referanslar

- Chart.js Docs: https://www.chartjs.org/
- NGINX Log Format: http://nginx.org/en/docs/http/ngx_http_log_module.html
- Benzer Feature: Dashboard sayfası (web/templates/dashboard.html)

---

## 📝 Claude Promptu

Bu PRD'yi Claude'a şöyle verebilirsiniz:

```
knetboot projesine Boot Statistics Dashboard özelliği ekleyeceğim.
PRD: .taskmaster/examples/boot-statistics-prd.md

Bu PRD'yi oku, implementasyon için detaylı task listesi oluştur ve
implementasyona başla. Önce backend (API endpoints, log parser),
sonra frontend (HTML, Chart.js) sırasıyla yap.

Her adımı tamamladıkça test et ve bana rapor et.
```

---

**Not**: Bu örnek PRD, Task Master yaklaşımını göstermek için hazırlanmıştır. Gerçek implementasyon farklılık gösterebilir.
