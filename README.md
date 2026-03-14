# Movie Recommendation System 🎬

Inside Out temalı, TMDB API destekli mobil film öneri ve arşivleme uygulaması.

## 🚀 Mevcut Durum (Backend)
- **Veri Kaynağı:** TMDB API üzerinden 200+ film çekildi.
- **Veritabanı:** SQLite kullanılarak ilişkisel model (Movies, Genres, Favorites) kuruldu.
- **API:** FastAPI ile RESTful endpointler oluşturuldu.
- **Özel Özellik:** "Inside Out" mantığıyla türlere göre duygu ve renk eşleştirmesi yapıldı.

## 🛠️ Kurulum
1. Kütüphaneleri yükleyin: `pip install -r requirements.txt`
2. Sunucuyu başlatın: `uvicorn main:app --reload`