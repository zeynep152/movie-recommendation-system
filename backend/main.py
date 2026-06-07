from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import hashlib
import random
from db_connection import get_db
from ml_logic import ml_manager

app = FastAPI(title="CINEMOD API")

# --- CORS AYARLARI ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- MODELLER (Pydantic) ---
class FavoriteRequest(BaseModel):
    user_id: int
    movie_id: int

class UserLogin(BaseModel):
    email: str
    password: str

# 🌟 YENİ: Kayıt işlemi için gerekli Pydantic Modeli
class UserRegister(BaseModel):
    username: str
    email: str
    password: str

class WatchlistRequest(BaseModel):
    user_id: int
    movie_id: int

# Şifreleri güvenli hale getiren yardımcı fonksiyon
def hash_password(password: str):
    return hashlib.sha256(password.encode()).hexdigest()

# Duygu ve Tür eşleşmeleri (Inside Out mantığı)
GENRE_COLORS = {
    28: {"name": "Aksiyon", "emotion": "Öfke"},
    35: {"name": "Komedi", "emotion": "Neşe"},
    18: {"name": "Dram", "emotion": "Hüzün"},
    27: {"name": "Korku", "emotion": "Korku"},
    10749: {"name": "Romantik", "emotion": "Sevgi"},
    878: {"name": "Bilim Kurgu", "emotion": "Merak"}
}

# --- AÇILIŞTA ML MODELİNİ ÇALIŞTIR ---
@app.on_event("startup")
def startup_event():
    ml_manager.build_knn()

# --- API ENDPOINT'LERİ ---

@app.post("/users/login")
async def login(req: UserLogin):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT id, username FROM users WHERE email=? AND password_hash=?", 
                   (req.email, hash_password(req.password)))
    user = cursor.fetchone()
    conn.close()
    if not user:
        raise HTTPException(status_code=401, detail="Hatalı giriş")
    return {"user_id": user["id"], "username": user["username"]}

# 🌟 YENİ: Kullanıcı Kayıt Endpoint'i (Register)
@app.post("/users/register")
async def register(req: UserRegister):
    conn = get_db()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)",
            (req.username, req.email, hash_password(req.password))
        )
        conn.commit()
        return {"status": "success", "message": "Kayıt başarılı"}
    except Exception as e:
        raise HTTPException(status_code=400, detail="Bu e-posta veya kullanıcı adı zaten kullanımda.")
    finally:
        conn.close()

@app.get("/recommendations/{user_id}")
async def get_recommendations(user_id: int):
    conn = get_db()
    cursor = conn.cursor()
    
    # Kullanıcının favorilerini çek
    cursor.execute("SELECT movie_id FROM favorites WHERE user_id = ?", (user_id,))
    favs = [row["movie_id"] for row in cursor.fetchall()]
    
    # Eğer hiç favori yoksa popüler filmleri döndür
    if not favs:
        cursor.execute("SELECT * FROM movies LIMIT 6")
        res = [dict(m) for m in cursor.fetchall()]
        conn.close()
        return res

    # kNN algoritması ile öneri üret
    recommendations = []
    for fav_id in favs:
        if fav_id in ml_manager.movie_index:
            idx = ml_manager.movie_index[fav_id]
            # En yakın 5 benzer filmi bul
            _, indices = ml_manager.model.kneighbors([ml_manager.matrix[idx]], n_neighbors=5)
            for i in indices[0]:
                mid = ml_manager.movie_ids[i]
                if mid not in favs:
                    cursor.execute("SELECT * FROM movies WHERE id=?", (mid,))
                    m = cursor.fetchone()
                    if m: recommendations.append(dict(m))
    
    conn.close()
    if not recommendations:
        return []
    # İlk 10 öneriyi döndür (Rastgele karıştırarak daha iyi bir deneyim sunarız)
    return random.sample(recommendations, min(len(recommendations), 10))

# --- DİĞER LİSTELER ---
@app.get("/movies/lists/popular")
async def popular():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM movies ORDER BY popularity DESC LIMIT 10")
    res = [dict(m) for m in cursor.fetchall()]
    conn.close()
    return res

# 🌟 YENİ: En Yüksek Puanlı Filmler Endpoint'i (Top Rated)
@app.get("/movies/lists/top-rated")
async def top_rated():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM movies ORDER BY vote_average DESC, vote_count DESC LIMIT 10")
    res = [dict(m) for m in cursor.fetchall()]
    conn.close()
    return res

# 🌟 YENİ: Mod Esintisi / Inside Out Duygu Analizi Endpoint'i
@app.get("/movies/lists/mood-esintisi")
async def mood_esintisi():
    conn = get_db()
    cursor = conn.cursor()
    
    # Sistemin o an rastgele seçtiği bir mod / duygu grubu
    genre_id = random.choice(list(GENRE_COLORS.keys()))
    mood_info = GENRE_COLORS[genre_id]
    
    # O türe ait filmleri çek (Veritabanında genre_ids içinde bu id geçiyor mu kontrolü)
    cursor.execute("""
        SELECT * FROM movies m 
        JOIN movie_genres mg ON m.id = mg.movie_id 
        WHERE mg.genre_id = ? 
        ORDER BY m.popularity DESC 
        LIMIT 10
    """, (genre_id,))
    movies = [dict(m) for m in cursor.fetchall()]
    conn.close()
    
    return {
        "mood_name": mood_info["name"],
        "emotion": mood_info["emotion"],
        "movies": movies
    }

@app.get("/favorites/{user_id}")
async def favorites(user_id: int):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT m.* FROM movies m JOIN favorites f ON m.id = f.movie_id WHERE f.user_id=?", (user_id,))
    res = [dict(m) for m in cursor.fetchall()]
    conn.close()
    return res

# Favori ekleme
@app.post("/favorites/add")
async def add_fav(req: FavoriteRequest):
    conn = get_db()
    try:
        cursor = conn.cursor()
        cursor.execute("INSERT INTO favorites (user_id, movie_id) VALUES (?,?)", (req.user_id, req.movie_id))
        conn.commit()
        return {"status": "ok"}
    except:
        return {"status": "error"}
    finally:
        conn.close()

@app.get("/watchlist/{user_id}")
async def get_watchlist(user_id: int):
    conn = get_db()
    cursor = conn.cursor()
    # Kullanıcının izleme listesindeki filmleri detaylarıyla getir
    cursor.execute("""
        SELECT * FROM movies m 
        JOIN watchlist w ON m.id = w.movie_id 
        WHERE w.user_id = ? 
    """, (user_id,))
    res = [dict(m) for m in cursor.fetchall()]
    conn.close()
    return res

# İzleme listesine ekleme
@app.post("/watchlist/add")
async def add_to_watchlist(req: WatchlistRequest):
    conn = get_db()
    try:
        cursor = conn.cursor()
        # Veritabanına izleme listesi kaydı ekle
        cursor.execute("INSERT INTO watchlist (user_id, movie_id) VALUES (?,?)", 
                       (req.user_id, req.movie_id))
        conn.commit()
        return {"status": "success", "message": "İzleme listesine eklendi"}
    except:
        return {"status": "exists", "message": "Zaten listede"}
    finally:
        conn.close()

@app.get("/user/{user_id}/emotion-profile")
async def get_user_emotion_profile(user_id: int):
    conn = get_db()
    cursor = conn.cursor()
    
    # 1. Kullanıcının favori film ID'lerini al
    cursor.execute("SELECT movie_id FROM favorites WHERE user_id = ?", (user_id,))
    fav_ids = [row["movie_id"] for row in cursor.fetchall()]
    
    if not fav_ids:
        conn.close()
        return {"profile": {}}

    # 2. Bu filmlerin türlerini say
    profile_counts = {"Neşe": 0, "Hüzün": 0, "Öfke": 0, "Korku": 0, "Sevgi": 0, "Merak": 0}
    
    for m_id in fav_ids:
        cursor.execute("SELECT genre_id FROM movie_genres WHERE movie_id = ?", (m_id,))
        genres = [row["genre_id"] for row in cursor.fetchall()]
        for g_id in genres:
            if g_id in GENRE_COLORS:
                emotion_key = GENRE_COLORS[g_id]["emotion"]
                profile_counts[emotion_key] += 1

    # 3. Yüzdelik hesapla
    total_points = sum(profile_counts.values())
    profile_percentages = {}
    
    if total_points > 0:
        for emotion, count in profile_counts.items():
            # Sadece 0'dan büyük olanları veya tümünü döndürebiliriz
            percentage = int((count / total_points) * 100)
            if percentage > 0:
                profile_percentages[emotion] = percentage
    
    conn.close()
    return {"profile": profile_percentages}