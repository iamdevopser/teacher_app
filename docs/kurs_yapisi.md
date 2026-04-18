Mevcut link ekleme yapısını koru ve iki davranış ekle:

Linke tıklandığında varsayılan tarayıcıda açılsın (mevcut davranış devam etsin)
Sadece kursun yayınlandığı/görüntülendiği menüde her link için bir “İndir” butonu ekle (kurs oluştur menüsüne ekleme)

“İndir” butonu linkteki dosyayı uygulama içinde indirip courses/{kurs}/{unite}/{konu}/files/ klasörüne kaydetsin

Uygulama root path’ini dinamik al, klasör yoksa oluştur, dosya adını çakışmaya karşı benzersiz yap (timestamp ekle), indirme başarısız olursa kayıt oluşturma

İndirilen dosya varsa buton durumunu “İndirildi / Yeniden indir” olarak güncelle

Harici servis, on-demand yapı veya ek bağımlılık kullanmadan tamamen local çalıştır.