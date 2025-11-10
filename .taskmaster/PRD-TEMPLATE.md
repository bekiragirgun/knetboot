# Product Requirements Document (PRD) - Template

**Proje**: knetboot
**Özellik**: [Özellik Adı]
**Versiyon**: [v2.5.0 / v3.0.0]
**Yazar**: [İsim]
**Tarih**: [YYYY-MM-DD]
**Durum**: [Draft / Review / Approved / In Progress / Completed]

---

## 📋 Özet

**Tek Cümle Özet**: [Bu özellik neyi sağlar, neden önemli?]

**Problem**: [Hangi problemi çözüyor?]

**Çözüm**: [Nasıl çözüyor?]

**Başarı Metrikleri**:
- [Metrik 1]: [Hedef değer]
- [Metrik 2]: [Hedef değer]

---

## 🎯 Hedefler ve Hedef Kitle

### Hedefler
1. [Birincil hedef]
2. [İkincil hedef]
3. [Uzun vadeli hedef]

### Hedef Kullanıcılar
- **Birincil**: [Sistem yöneticileri / Developers / Son kullanıcılar]
- **İkincil**: [...]

### Kullanım Senaryoları
1. **[Senaryo 1]**: [Kullanıcı X, Y yapmak istiyor, çünkü Z]
2. **[Senaryo 2]**: [...]

---

## 📐 Fonksiyonel Gereksinimler

### Temel Özellikler (Must Have)
- [ ] **[Özellik 1]**: [Açıklama]
  - Input: [...]
  - Output: [...]
  - Validasyon: [...]

- [ ] **[Özellik 2]**: [Açıklama]

### İkincil Özellikler (Should Have)
- [ ] **[Özellik 3]**: [Açıklama]

### Gelecek Özellikler (Nice to Have)
- [ ] **[Özellik 4]**: [Açıklama]

---

## 🏗️ Teknik Gereksinimler

### Mimari
- **Frontend**: [HTML/Bootstrap / React / Vue]
- **Backend**: [Flask route, API endpoint]
- **Database**: [YAML file / JSON / SQLite]
- **External Services**: [API calls, dependencies]

### Teknoloji Stack
- **Diller**: Python 3.x, JavaScript ES6+, HTML5, CSS3
- **Framework**: Flask, Bootstrap 5
- **Libraries**: [requests, yaml, json, etc.]
- **Tools**: [nginx, systemd, iPXE, cloud-init]

### Veri Modeli
```yaml
# Örnek veri yapısı
feature:
  id: "unique_id"
  name: "Feature Name"
  config:
    param1: "value1"
    param2: "value2"
  status: "active|inactive"
  created: "2025-11-08"
```

### API Endpoints
1. **GET /admin/api/[resource]**
   - Response: `{data: [...], status: "success"}`

2. **POST /admin/api/[resource]/[action]**
   - Request: `{param1: "value", param2: "value"}`
   - Response: `{message: "...", status: "success|error"}`

---

## 🎨 UI/UX Tasarım

### Sayfa Yapısı
```
/admin/[feature-page]/
├── Header (Navigation)
├── Main Content
│   ├── Info Card
│   ├── Configuration Form
│   └── Action Buttons
└── Footer
```

### Wireframe / Mockup
```
+----------------------------------+
|  Header / Breadcrumb             |
+----------------------------------+
|  [Info Card]                     |
|  Status: Active | Toggle Switch  |
+----------------------------------+
|  Configuration Form              |
|  [ Field 1 ]                     |
|  [ Field 2 ]                     |
|  [Save] [Cancel]                 |
+----------------------------------+
```

### UI Components
- Bootstrap 5 Cards
- Forms (input, select, checkbox)
- Buttons (primary, success, danger)
- Tables (responsive, sortable)
- Modals (confirm dialogs)
- Toast notifications

### Color Scheme
- Primary: #3498db
- Success: #2ecc71
- Warning: #f39c12
- Danger: #e74c3c
- Dark: #2c3e50

---

## 🔐 Güvenlik Gereksinimleri

- [ ] Input validation (XSS, SQL injection)
- [ ] CSRF protection (Flask forms)
- [ ] File upload security (type, size limits)
- [ ] Secure password handling (hashing)
- [ ] Permission checks (admin only)
- [ ] Audit logging (who did what, when)

---

## ⚡ Performans Gereksinimleri

- **Response Time**: < 200ms (API), < 1s (Page load)
- **Throughput**: [X requests/second]
- **Scalability**: [Concurrent users]
- **Resource Usage**: CPU < 50%, Memory < 1GB

---

## 🧪 Test Gereksinimleri

### Test Senaryoları
1. **Happy Path**: [Normal kullanım senaryosu]
2. **Edge Cases**: [Sınır durumları]
3. **Error Handling**: [Hata senaryoları]

### Test Ortamı
- OS: Ubuntu 24.04 Server
- Network: Libvirt (192.168.122.0/24)
- VM: [Specs]

### Kabul Kriterleri
- [ ] Tüm unit testler geçiyor
- [ ] Integration testler başarılı
- [ ] UI responsive (mobile, tablet, desktop)
- [ ] Cross-browser (Chrome, Firefox, Edge)
- [ ] Performance benchmarks karşılanıyor

---

## 📦 Bağımlılıklar

### Teknik Bağımlılıklar
- Python >= 3.8
- Flask >= 2.0
- [Diğer paketler]

### Özellik Bağımlılıklar
- [Önce X özelliği tamamlanmalı]
- [Y servisi çalışıyor olmalı]

### Dış Bağımlılıklar
- [External API]
- [Third-party service]

---

## 🗺️ Implementasyon Planı

### Faz 1: Temel Altyapı (1 hafta)
- [ ] Database schema oluştur
- [ ] API endpoints yaz
- [ ] Basic CRUD operations

### Faz 2: UI Geliştirme (1 hafta)
- [ ] HTML templates
- [ ] JavaScript interactivity
- [ ] CSS styling

### Faz 3: Integration ve Test (3 gün)
- [ ] Backend-Frontend integration
- [ ] Unit tests
- [ ] Integration tests

### Faz 4: Dokümantasyon ve Deployment (2 gün)
- [ ] User documentation
- [ ] API documentation
- [ ] Deployment guide

**Toplam Süre**: ~2.5 hafta

---

## 🚧 Riskler ve Kısıtlamalar

### Riskler
1. **[Risk 1]**: [Açıklama]
   - Olasılık: [Düşük/Orta/Yüksek]
   - Etki: [Düşük/Orta/Yüksek]
   - Mitigation: [Nasıl önlenir/azaltılır]

2. **[Risk 2]**: [...]

### Kısıtlamalar
- Budget: [Varsa]
- Time: [Deadline]
- Resources: [Mevcut kaynak kısıtları]
- Technical: [Teknik kısıtlamalar]

---

## 📊 Başarı Metrikleri ve KPI'lar

- **Kullanım**: [X kullanıcı/gün, Y işlem/hafta]
- **Performans**: [Response time < Zms]
- **Kalite**: [Bug rate < %X]
- **Kullanıcı Memnuniyeti**: [Feedback score > Y/10]

---

## 🔄 Gelecek İyileştirmeler

### v2 (Sonraki Versiyon)
- [ ] [İyileştirme 1]
- [ ] [İyileştirme 2]

### v3 (Uzun Vadeli)
- [ ] [İyileştirme 3]
- [ ] [İyileştirme 4]

---

## 📚 Referanslar ve Kaynaklar

- [Benzer özellik]: [Link veya dosya]
- [Dokümantasyon]: [URL]
- [External API docs]: [URL]
- [Design inspiration]: [URL]

---

## 📝 Değişiklik Geçmişi

| Versiyon | Tarih | Yazar | Değişiklik |
|----------|-------|-------|------------|
| 1.0 | 2025-11-08 | Bekir | İlk taslak |
| 1.1 | ... | ... | ... |

---

## ✅ Onay

- [ ] Product Owner: [İsim] - [Tarih]
- [ ] Tech Lead: [İsim] - [Tarih]
- [ ] Stakeholder: [İsim] - [Tarih]

---

**Not**: Bu PRD template'i Claude ile kullanmak için tasarlanmıştır. PRD'yi doldurup Claude'a "Bu PRD'yi oku ve implementasyon için task listesi oluştur" diyebilirsiniz.
