# knetboot - Claude Task Master Sistemi

Bu dizin, knetboot projesinde Claude AI ile daha etkili çalışmak için hazırlanmış Task Master sistemini içerir.

## 📁 Dosya Yapısı

```
.taskmaster/
├── README.md                      # Bu dosya
├── PROMPTS.md                     # Detaylı prompt şablonları
├── QUICK-REFERENCE.md             # Hızlı referans kılavuzu
├── PRD-TEMPLATE.md                # Product Requirements Document şablonu
└── examples/
    └── boot-statistics-prd.md     # Örnek PRD
```

## 🚀 Hızlı Başlangıç

### 1. Basit Görev
Küçük işler için direkt prompt yaz:

```
knetboot web UI'ya restart butonu ekle. Dashboard'a, NGINX restart için.
Bootstrap 5, danger button, confirm modal ile. Implement et.
```

### 2. Orta Görev
Biraz daha detaylı prompt:

```
knetboot'a Ubuntu 22.04 Server autoinstall profili ekle:
- Base: config/autoinstall/ubuntu-server/
- Hostname: ubuntu-2204
- Packages: docker, k8s-tools
- Network: Static IP

Task listesi oluştur ve implement et.
```

### 3. Karmaşık Görev
PRD kullan:

```
1. PRD-TEMPLATE.md kopyala → .taskmaster/prds/my-feature.md
2. PRD'yi doldur
3. Claude'a ver:

"knetboot için .taskmaster/prds/my-feature.md PRD'sini oku.
Implementasyon için detaylı task listesi oluştur ve
faz faz implement et. Her faz sonunda test et."
```

## 📖 Kullanım Kılavuzu

### Prompt Yazma Prensipleri

**✅ İYİ PROMPT**:
```
knetboot web/app.py'a yeni API endpoint ekle:
POST /admin/api/images/upload
- File upload (multipart/form-data)
- Validate: .iso, .img, max 10GB
- Save to: /opt/knetboot/assets/custom/
- Return: {status, filename, size}
Hata yönetimi ekle, test et.
```

**❌ KÖTÜ PROMPT**:
```
Image upload ekle.
```

### Task Listesi İsteme

Claude'un büyük işleri organize etmesi için:

```
knetboot'a user authentication sistemi ekle (Flask-Login).
Bu iş için detaylı task listesi oluştur:
- Database schema
- Login/logout routes
- Session management
- Password hashing
- UI (login page, protect routes)
Her task için alt görevler belirt.
```

Claude otomatik olarak şuna benzer bir liste oluşturur:

```
1. [pending] Database schema oluştur
   - users tablosu (id, username, password_hash, created_at)
   - SQLite migration script

2. [pending] Backend authentication
   - Flask-Login install
   - User model (SQLAlchemy/ORM)
   - Login route (/admin/login)
   - Logout route (/admin/logout)
   - Password hashing (bcrypt)

3. [pending] Frontend UI
   - login.html template
   - Form validation
   - Error messages
   ...
```

### PRD Kullanımı

Büyük feature'lar için:

1. **PRD Oluştur**:
   ```bash
   cp .taskmaster/PRD-TEMPLATE.md .taskmaster/prds/user-auth.md
   ```

2. **Doldur**: Tüm bölümleri eksiksiz doldur

3. **Claude'a Ver**:
   ```
   knetboot için .taskmaster/prds/user-auth.md PRD'sini oku.

   Implementasyon planı:
   - Faz 1: Database + Backend
   - Faz 2: UI
   - Faz 3: Testing

   Her fazı tamamla, test et, sonraki faza geç.
   Progress raporla.
   ```

## 🎯 Prompt Şablonları

### Özellik Geliştirme
```
knetboot [modul]'e [özellik] ekle:
- [Gereksinim 1]
- [Gereksinim 2]
Referans: [benzer_kod]. Implement et.
```

### Bug Fix
```
knetboot'ta hata: [açıklama]
Lokasyon: [dosya:satır]
Repro: [adımlar]
Loglar: [log_output]
Fix yap ve test et.
```

### Dokümantasyon
```
knetboot [dosya.md] güncelle:
- [Değişiklik 1]
- [Değişiklik 2]
Mevcut formatı koru.
```

### Test
```
knetboot [özellik] için test senaryosu yaz ve çalıştır:
1. [Senaryo 1]: [adımlar] → [sonuç]
2. [Senaryo 2]: ...
Sonuçları raporla.
```

Daha fazla şablon için: [PROMPTS.md](PROMPTS.md)

## 📚 Dokümantasyon

- **[PROMPTS.md](PROMPTS.md)**:
  - Kapsamlı prompt kütüphanesi
  - Kategorilere göre organize
  - Örneklerle açıklanmış

- **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)**:
  - Hızlı kullanım için kısa şablonlar
  - Kısayollar tablosu
  - En sık kullanılan promptlar

- **[PRD-TEMPLATE.md](PRD-TEMPLATE.md)**:
  - Product Requirements Document şablonu
  - Büyük feature'lar için
  - Tüm bölümler açıklamalı

- **[examples/](examples/)**:
  - Örnek PRD'ler
  - Gerçek kullanım senaryoları

## 💡 Pro Tips

### 1. Spesifik Ol
```
❌ "Web UI düzelt"
✅ "web/templates/dashboard.html'de service status card'ların
   responsive olmama sorununu düzelt. Mobile'da yan yana değil
   alt alta dizilmeli."
```

### 2. Referans Ver
```
✅ "config/autoinstall/ubuntu-server/user-data dosyasını referans
   alarak Debian 12 için benzer bir autoinstall config oluştur."
```

### 3. Test İste
```
✅ "Implementasyon sonrası:
   1. Unit test yaz
   2. Manuel test senaryosu çalıştır
   3. Sonuçları raporla"
```

### 4. Adım Adım İlerle
```
✅ "Bu işi 3 faza böl:
   Faz 1: Backend API
   Faz 2: Frontend UI
   Faz 3: Integration + Test
   Her faz sonunda bana sor, onayımla devam et."
```

### 5. Bağlam Ver
```
✅ "knetboot Flask app (web/app.py) kullanıyor.
   Mevcut route pattern'i: @app.route('/admin/...')
   Bu pattern'i takip ederek yeni route ekle."
```

## 🔄 İş Akışı Örnekleri

### Senaryo 1: Hızlı Feature
```
1. Fikir: "Dashboard'a disk kullanımı göster"
2. Prompt: "knetboot dashboard'a disk usage card ekle.
            `df -h` komutu çalıştır, Bootstrap card'da göster.
            Referans: service status cards."
3. Claude implement eder
4. Test et
5. Commit/push
```

### Senaryo 2: Orta Boy Feature
```
1. Fikir: "Image upload özelliği"
2. QUICK-REFERENCE.md'den şablon al
3. Prompt oluştur (spesifik gereksinimlerle)
4. Claude task listesi oluşturur
5. Her task'ı sırayla implement et
6. Test, commit, push
```

### Senaryo 3: Büyük Feature
```
1. Fikir: "User authentication sistemi"
2. PRD-TEMPLATE.md kopyala
3. PRD doldur (hedefler, gereksinimler, tasarım, vb.)
4. Claude'a PRD ver
5. Claude detaylı plan oluşturur
6. Faz faz ilerle
7. Her faz: implement → test → review
8. Final test + dokümantasyon
9. Commit, push, deploy
```

## 🎓 Öğrenme Kaynakları

### Claude Task Master
- GitHub: https://github.com/eyaltoledano/claude-task-master
- Docs: Task Master documentation

### knetboot
- Main README: [../README.md](../README.md)
- Config Guide: [../CONFIG-GUIDE.md](../CONFIG-GUIDE.md)
- Autoinstall: [../config/autoinstall/README.md](../config/autoinstall/README.md)

### AI Prompting
- Claude Prompt Engineering: https://docs.anthropic.com/claude/docs/prompt-engineering
- Best Practices: Clear, specific, contextual prompts

## ❓ Sık Sorulan Sorular

### Claude task listesi oluşturmuyor?
**Çözüm**: Explicitly iste:
```
"Bu iş için detaylı task listesi oluştur ve her task'ı
sırayla implement et."
```

### PRD çok uzun, Claude karışıyor?
**Çözüm**: PRD'yi bölümlere ayır:
```
"Önce 'Fonksiyonel Gereksinimler' bölümünü oku ve task listesi oluştur.
Sonra 'Teknik Gereksinimler'e geçeriz."
```

### Kod kalitesi düşük?
**Çözüm**: Standartları belirt:
```
"PEP 8 coding standards kullan.
Type hints ekle.
Docstring yaz (Google style).
Hata yönetimi ekle (try/except).
Logging ekle."
```

### Test yok?
**Çözüm**: Test'i requirement yap:
```
"Her feature için:
1. Unit test yaz (pytest)
2. Integration test yaz
3. Manuel test senaryosu oluştur
4. Tüm testleri çalıştır ve raporla"
```

## 🤝 Katkıda Bulunma

Bu Task Master sistemini geliştirmek için:

1. Yeni prompt şablonları ekle: `PROMPTS.md`
2. Örnek PRD'ler ekle: `examples/`
3. İyileştirme önerileri: GitHub issue

## 📝 Versiyon Geçmişi

- **v1.0.0** (2025-11-08): İlk versiyon
  - PROMPTS.md: Detaylı prompt kütüphanesi
  - QUICK-REFERENCE.md: Hızlı referans
  - PRD-TEMPLATE.md: PRD şablonu
  - Örnek PRD: Boot Statistics Dashboard

---

**Proje**: knetboot v2.4.0
**Task Master Version**: 1.0.0
**Son Güncelleme**: 2025-11-08
**Yazar**: Bekir

**Not**: Bu sistem Claude (Anthropic) ile optimize edilmiş şekilde çalışır, ancak diğer LLM'lerle de kullanılabilir (GPT-4, etc.).
