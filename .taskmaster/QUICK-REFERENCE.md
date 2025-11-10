# knetboot - Quick Prompt Reference

Hızlı kullanım için sık kullanılan prompt şablonları.

## 🚀 Hızlı Başlangıç

### Yeni Özellik Ekle
```
knetboot'a [özellik_adı] ekle. [Kısa açıklama].
Referans: [benzer_özellik]. Task listesi oluştur ve implement et.
```

### Bug Fix
```
knetboot'ta hata: [açıklama]. Lokasyon: [dosya:satır].
Repro: [adımlar]. Fix yap ve test et.
```

### Dokümantasyon
```
knetboot [dosya].md güncelle: [değişiklikler].
Mevcut formatı koru, versiyon: v2.4.0.
```

---

## 📋 Özellik Şablonları

### Web UI Sayfası
```
knetboot web UI: yeni [sayfa_adı] sayfası ekle.
- Route: /admin/[sayfa]
- Template: web/templates/[sayfa].html
- Özellikler: [liste]
Referans: dashboard sayfası. Implement et.
```

### API Endpoint
```
knetboot API: POST /admin/api/[resource]/[action]
Input: {[params]}
Output: {[response]}
Hata yönetimi ekle, dokümante et.
```

### Autoinstall Profil
```
config/autoinstall/[distro]-[variant]/ oluştur:
- Base: ubuntu-server
- Packages: [liste]
- Network: [DHCP/Static]
user-data + meta-data + README.md ekle.
```

### iPXE Menü
```
config/menus/[menu].ipxe: yeni boot entry ekle:
Kernel: [path + args]
Initrd: [path]
Test: VM ile PXE boot.
```

---

## 🔧 Sistem Görevleri

### Servis Debug
```
[servis_adı] servisi sorun: [açıklama]
Loglar: journalctl -u [servis] -n 50
Debug et ve düzelt.
```

### Config Güncelle
```
[config_dosyası] güncelle: [değişiklikler]
Syntax check yap, servisi restart et, test et.
```

### Deployment
```
knetboot v[x.y.z] deploy et [sunucu].
Checklist: backup, pull, config, restart, test.
```

---

## 🧪 Test Promptları

### Manuel Test
```
[özellik] test et:
1. [Senaryo 1]: [adımlar] → [sonuç]
2. [Senaryo 2]: ...
Sonuçları raporla.
```

### Integration Test
```
knetboot end-to-end test: PXE boot → OS install
Client VM, [distro] autoinstall, raporla.
```

---

## 📊 Analiz Promptları

### Kod Analizi
```
[dosya/modül] analiz et:
- Mimari
- İyileştirmeler
- Potansiyel sorunlar
Rapor hazırla.
```

### Güvenlik Audit
```
knetboot güvenlik analizi: [kapsam]
OWASP Top 10 kontrol et, bulguları raporla.
```

### Performans
```
knetboot performans test: [alan]
Metrikler: [boot time, API latency, etc.]
Benchmark raporu.
```

---

## 🔍 Araştırma

### Teknoloji Araştır
```
[teknoloji] araştır, knetboot entegrasyonu için:
- Nasıl çalışır
- Avantaj/dezavantaj
- Implementasyon önerisi
Rapor + POC.
```

### Best Practices
```
[alan] best practices araştır:
- Industry standards
- Mevcut kod analizi
- İyileştirmeler
Uygula ve dokümante et.
```

---

## 💾 Veri/Config

### DHCP Config
```
DHCP: network [IP/subnet], range [start-end], gateway [IP].
Template güncelle, test et.
```

### Image Ekle
```
config/images.yaml: [distro] image ekle
- ID, name, type, paths
- Menu generator çalıştır
```

---

## 🎨 UI/UX

### Bootstrap Component
```
[sayfa]: Bootstrap 5 [component_tipi] ekle
Data: [API endpoint]
Responsive, mevcut tema.
```

### Form Oluştur
```
[sayfa]: [form_adı] formu ekle
Fields: [liste]
Validation, submit handler, API post.
```

---

## 📈 Raporlama

### Changelog
```
CHANGELOG.md: v[x.y.z] ekle
- Features: [liste]
- Fixes: [liste]
- Breaking: [liste]
```

### Progress Report
```
[özellik] progress raporu:
- Tamamlanan: [liste]
- Devam eden: [liste]
- Planlanan: [liste]
Status: [%]
```

---

## 🎯 Kısayollar

| Komut | Açıklama |
|-------|----------|
| `+ ui [sayfa]` | Web UI sayfası ekle |
| `+ api [endpoint]` | API endpoint ekle |
| `+ autoinstall [profil]` | Autoinstall profil ekle |
| `+ menu [entry]` | iPXE menü entry ekle |
| `fix [sorun]` | Bug fix |
| `test [özellik]` | Test senaryosu |
| `doc [dosya]` | Dokümantasyon güncelle |
| `deploy [versiyon]` | Production deploy |
| `analyze [kapsam]` | Kod/güvenlik analizi |
| `research [konu]` | Teknoloji araştır |

---

## 💡 Pro Tips

1. **Spesifik Ol**: Dosya yolları, satır numaraları, örnek kod ver
2. **Referans Göster**: Benzer kod/özelliği örnek göster
3. **Task Listesi İste**: Büyük işleri alt görevlere böl
4. **Test İste**: Her değişiklik sonrası test senaryosu iste
5. **Dokümante Ettir**: Değişiklikleri dokümantasyona yansıt

---

## 📚 Ek Kaynaklar

- Detaylı Promptlar: [PROMPTS.md](PROMPTS.md)
- Proje Dokümantasyonu: [../README.md](../README.md)
- Autoinstall Rehberi: [../config/autoinstall/README.md](../config/autoinstall/README.md)
- Config Rehberi: [../CONFIG-GUIDE.md](../CONFIG-GUIDE.md)

---

**Versiyon**: 1.0.0
**Son Güncelleme**: 2025-11-08
