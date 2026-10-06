🎬 CINEMOD - Yapay Zeka Destekli & Duygu Odaklı Film Öneri Uygulaması

CINEMOD, kullanıcıların izleme alışkanlıklarını, beğeni geçmişini ve anlık duygu durumlarını analiz ederek kişiselleştirilmiş film önerileri sunan Full-Stack (Flutter + FastAPI) mobil uygulamadır.

TMDB API entegrasyonu ile zenginleştirilmiş film kütüphanesini KNN (k-Nearest Neighbors) tabanlı makine öğrenmesi motoruyla birleştirerek kullanıcılara benzersiz bir sinematik keşif deneyimi sunar.

✨ Öne Çıkan Özellikler

1. 🤖 Hibrit AI Öneri Motoru (KNN)

Kişiselleştirilmiş Öneriler: Kullanıcının favori listesi ve etkileşim geçmişi üzerinden k-Nearest Neighbors (KNN) algoritması kullanılarak içerik tabanlı (Content-Based) ve kullanıcı odaklı öneriler üretilir.

Moda Özel Rastgele Öneriler: Anlık ruh haline göre dinamik film keşfi imkanı.

Popüler & En Yüksek Puanlılar: Güncel ve trend filmlerin TMDB API üzerinden akıcı şekilde listelenmesi.

2. 📊 Duygu Analizi & Profilleme

Duygu Karakteri Çıkarımı: Kullanıcının favoriye eklediği filmlerin tür ağırlıkları analiz edilerek kişisel "Duygu Profili" (%40 Neşe, %30 Melankoli, %20 Gerilim, %10 Korku vb.) hesaplanır.

Görsel İstatistikler: Profil ekranında canlı grafikler ve dinamik ilerleme göstergeleri ile kullanıcı duygu dağılımı görselleştirilir.

3. 📱 Gelişmiş UI/UX ve Performans

Sliver Mimari: Film detay ekranında esnek ve modern kaydırma deneyimi sunulur. Görsel kaydırıldıkça poster akıcı bir şekilde üst bara kilitlenir.

RAM Optimizasyonu: Ana sayfa ve uzun listelerde akıllı renderlama ve verimli bellek yönetimi ile performans yüksek tutulur.

Anlık Bildirimler: Favorilere veya izleme listesine film eklendiğinde kullanıcıya anlık görsel geribildirim sağlanır.

4. 📂 Kişisel Sinema Arşivi

Favoriler & İzleme Listesi (Watchlist): Beğenilen ve gelecekte izlenmesi planlanan filmlerin tek tıkla veritabanında saklanması ve kolayca yönetilmesi.

🛠️ Teknoloji Yığını (Tech Stack)

Frontend (Mobil Uygulama)

Framework: Flutter (Dart)

Arayüz / Mimari: CustomScrollView, Slivers, Material 3

State & Oturum: UserSession, SharedPreferences

HTTP İletişimi: http paketi & JSON Parsing

Backend (API & AI Service)

Framework: FastAPI (Python)

Makine Öğrenmesi: Scikit-Learn (k-NN / Cosine Similarity)

Sunucu / ORM: Uvicorn, Pydantic

Veritabanı: SQLite 3 & TMDB REST API

📁 Proje Dizin Yapısı

movie-recommendation-system/
├── backend/          # FastAPI REST API, AI/ML tavsiye servisleri & route'lar
├── data/             # Film veri setleri ve duygu etiketleme dosyaları
├── database/         # SQLite veritabanı ve bağlantı bileşenleri
├── movie_app/        # Flutter mobil uygulama kütüphanesi ve UI kodları
│   ├── lib/
│   │   ├── models/   # Movie & User modelleri
│   │   ├── screens/  # Login, Home, Detail, Profile ekranları
│   │   └── services/ # ApiService & UserSession servisleri
├── .env              # Çevre değişkenleri ve API anahtarları
├── requirements.txt  # Python backend bağımlılıkları
└── README.md         # Proje dokümantasyonu


🚀 Kurulum ve Çalıştırma

1. Backend (FastAPI) Kurulumu

# Proje ana dizinine gidin
cd movie-recommendation-system

# Gerekli Python paketlerini yükleyin
pip install -r requirements.txt

# Backend klasörüne geçip sunucuyu başlatın
cd backend
uvicorn main:app --host 0.0.0.0 --port 8000 --reload


2. Frontend (Flutter) Kurulumu

# Flutter uygulama dizinine gidin
cd movie_app

# Bağımlılıkları çekin
flutter pub get

# Uygulamayı emülatör veya cihazda çalıştırın
flutter run


🔮 Gelecek Yol Haritası (Roadmap)

Projenin bir sonraki aşamalarında eklenmesi planlanan özellikler:

[ ] Sosyal İletişim: Arkadaş ekleme ve arkadaşların duygu profilleri ile film listelerini inceleyebilme.

[ ] Zaman Bazlı Duygu Günlüğü: Aylık ve yıllık izleme modlarının tarihsel analizi.

[ ] Çevrimdışı Senkronizasyon: İnternet bağlantısı olmadan da izleme listesine erişim ve yerel önbellekleme.

[ ] Gelişmiş Filtreleme: Süre, yapım yılı ve yönetmen bazlı detaylı arama modülleri.
