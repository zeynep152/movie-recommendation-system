# Inside Up 🧠✨ | Ruh Haline Göre Film Keşfi

**Inside Up**, kullanıcıların o anki duygusal durumlarına (Neşe, Üzüntü, Öfke, Korku vb.) göre en uygun sinematik deneyimi bulmalarını sağlayan, yüksek estetik odaklı bir Flutter mobil uygulamasıdır. 

"Zihninin hangi köşesindesin?" sorusundan yola çıkarak, duyguları renklerle ve ışıklarla harmanlayan premium bir kullanıcı deneyimi sunar.

---

## 🎨 Tasarım Felsefesi (Premium UI/UX)

Uygulama, modern mobil tasarım trendlerini takip ederek şu prensipler üzerine inşa edilmiştir:

- **Sapphire Dark Mode:** Göz yormayan, derinlik hissi veren sapphire-lacivert ve siyah gradyan geçişli arka plan.
- **Dinamik Neon Glow:** Her film kartı, temsil ettiği duygunun rengini (Örn: Neşe için Altın Sarı, Üzüntü için Neon Mavi) yumuşak bir ışık hüzmesi (`BoxShadow`) olarak arka plana yansıtır.
- **Horizontal Discovery:** İçeriklerin Netflix tarzı yatay akışla sunulmasıyla modern ve akıcı bir navigasyon sağlanmıştır.
- **Glassmorphism:** Arama çubuğu ve navigasyon barında şeffaflık ve buzlu cam efektleri kullanılarak görsel hiyerarşi korunmuştur.

---

## 🚀 Teknik Özellikler

- **Dinamik Gradyanlar:** `LinearGradient` ve `RadialGradient` kullanılarak oluşturulan derinlikli UI.
- **Hero Animations:** Sayfa geçişlerinde film posterlerinin akıcı bir şekilde taşınması.
- **Özel Widget Yapısı:** Tekrar kullanılabilir (reusable) `MoodSphere` ve `MovieCard` widget'ları ile temiz kod mimarisi.
- **Responsivity:** `MediaQuery` ile farklı ekran boyutlarına ve cihazlara tam uyum.
- **Interaktif Mood Palette:** Kullanıcının ruh halini seçebileceği özel tasarlanmış ikonik buton seti.

---

## 🛠️ Kullanılan Teknolojiler

- **Framework:** Flutter (Dart)
- **Veri Kaynağı:** [Buraya kullandığın API'yi yaz, örn: TMDB API / Mock Data]
- **Tasarım Araçları:** [Örn: Figma / Photoshop]

---

## 🏗️ Kurulum

Projeyi yerel makinenizde çalıştırmak için:

1. Depoyu klonlayın:
   ```bash
   git clone [https://github.com/kullaniciadin/movie_app.git](https://github.com/kullaniciadin/movie_app.git)