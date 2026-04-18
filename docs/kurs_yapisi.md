Flutter Teacher App projesinde aşağıdaki düzenlemeleri yap:

1. Sidebar Menu > "Kurslarım" altındaki:
   - "Kurslar" menüsünü "Kurs Oluştur" olarak değiştir
   - "Derslerim" menüsünü "Kurslarım" olarak değiştir
   - Tüm route, navigation ve label referanslarını buna göre güncelle

2. Kurs oluşturma (Create Course) akışında:
   - İlk adımda bulunan "Ders / Branş" alanını zorunlu kategori alanı yap
   - Girilen değeri course modeline "category" olarak kaydet

3. Kursların listelendiği ekranda:
   - Tüm kursları "category" alanına göre grupla
   - Aynı kategoriye sahip kursları tek başlık altında listele
   - Örnek: "Türkçe", "Matematik" gibi dinamik kategori başlıkları oluştur

4. Bu yapı:
   - Local state veya mevcut backend ile çalışsın
   - Ek servis, on-demand usage veya external dependency kullanılmasın