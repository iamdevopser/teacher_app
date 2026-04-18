Flutter Teacher App projesinde "Kurslarım" modülünde aşağıdaki geliştirmeleri yap:

1. 2. Sidebar (Course Sidebar) yapısını güncelle:
   - Üstte "Kategoriler" adlı bir ana menü (folder) oluştur
   - Bu menü expandable (Dropdown) yapıda olsun

2. Kategori yapısı:
   - Kurs oluşturma adımındaki "Ders / Branş" alanını course modelinde "category" olarak kullan
   - Tüm kursları bu "category" alanına göre grupla
   - Her benzersiz category değeri, "Kategoriler" altında bir alt klasör olarak listelensin
   - Bu alt klasörler de expandable (Dropdown) olsun

3. İçerik hiyerarşisi:
   - Kategori (örn: Türkçe, Matematik)
       → Altında o kategoriye ait kurslar listelensin
       → Kursa tıklanınca mevcut yapıdaki gibi kurs detay sayfası açılsın

4. UI davranışı:
   - Expand/Collapse state local state ile yönetilsin
   - Aynı anda birden fazla kategori açık olabilir
   - Boş kategori gösterilmesin
   - Liste dinamik olarak güncellensin (yeni kurs eklenince otomatik yansısın)

5. Teknik:
   - Ek servis veya on-demand yapı kullanma
   - Mevcut state management yapısını kullan (Provider / Riverpod / setState ne varsa)
   - Sidebar componentini reusable ve scalable olacak şekilde refactor et