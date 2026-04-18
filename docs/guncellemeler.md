Flutter Teacher App projesinde aşağıdaki geliştirmeleri yap:

----------------------------------
1. ANA SIDEBAR (LEFT MENU)
----------------------------------
- "Kurslarım" ana menü ismini "Akademi" olarak değiştir
- Route, navigation ve tüm referansları güncelle

----------------------------------
2. COURSE SIDEBAR (2. SIDEBAR)
----------------------------------
- Kurs oluşturma ekranında kullanılan "category (Ders/Branş)" yapısını aynen burada kullan

Yeni yapı:

- "Kategoriler" adlı ana klasör ekle (expandable)
- Tüm kursları course.category alanına göre grupla

UI hiyerarşisi:
Kategoriler
   → Türkçe (expandable)
        → Kurs 1
        → Kurs 2
   → Matematik (expandable)
        → Kurslar...

Davranış:
- ExpansionTile yapısı kullan
- Kategori ve kurslar dinamik oluşturulsun
- Kursa tıklanınca mevcut detail page açılsın
- Boş kategori gösterme
- State local yönetilsin (setState / Provider vs.)

----------------------------------
3. PLANLARIM SAYFASI - TABBAR FIX
----------------------------------
Sorun:
TabBar’a tıklanınca içerik değişmiyor

Çözüm:
- TabController düzgün bağlanmalı
- TabBar + TabBarView senkron çalışmalı
- Controller lifecycle doğru yönetilmeli (initState / dispose)

Beklenen:
- Tab’a tıklayınca içerik anında değişmeli
- Swipe ile de değişmeli (opsiyonel)

----------------------------------
4. PLANLARIM - BUTON İSİMLERİ
----------------------------------
Tüm alt menülerde aynı olan "Raporu Paylaş" butonunu dinamik hale getir:

Kurallar:
- Haftalık Program → "Haftalık Planı Paylaş"
- Yıllık Plan → "Yıllık Planı Paylaş"
- Günlük Plan → "Günlük Planı Paylaş"
- Dokümanlar → "Dokümanı Paylaş"
- Projeler → "Projeyi Paylaş"

Teknik:
- Hardcoded string kullanma
- Aktif tab’a göre label üret (enum / map önerilir)

----------------------------------
5. GENEL
----------------------------------
- Mevcut mimariyi bozma
- Ek servis / on-demand yapı kullanma
- Kodları reusable ve scalable yaz