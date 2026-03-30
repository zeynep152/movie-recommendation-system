from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel
import sqlite3
from typing import List, Optional
from sklearn.neighbors import NearestNeighbors
import numpy as np


app = FastAPI(title="Movie Insight API", description="Inside Out Temalı Film Uygulaması Backend")


# --- GLOBAL ML MODEL ---
model = None
matrix = None
movie_ids = None
movie_index = None

# --- VERİTABANI YARDIMCISI ---
def get_db():
    # 'r' harfi dosya yolu hatalarını (escape sequence) engeller
    conn = sqlite3.connect(r"database/movies.db")
    conn.row_factory = sqlite3.Row  # Verilerin sözlük (dict) gibi gelmesini sağlar
    return conn

# --- MODELLER (Frontend'den gelecek veriler için) ---
class FavoriteRequest(BaseModel):
    user_id: int
    movie_id: int

class UserRegister(BaseModel):
    username: str
    email: str
    password: str

# --- SABİTLER ---
GENRE_COLORS = {
    28: {"name": "Aksiyon", "color": "#FF0000", "emotion": "Öfke"},
    35: {"name": "Komedi", "color": "#FFFF00", "emotion": "Neşe"},
    18: {"name": "Dram", "color": "#0000FF", "emotion": "Üzüntü"},
    10749: {"name": "Romantik", "color": "#FFC0CB", "emotion": "Sevgi"},
    27: {"name": "Korku", "color": "#800080", "emotion": "Korku"}
}


def build_knn():
    global model, matrix, movie_ids, movie_index

    conn = get_db()
    cursor = conn.cursor()

    cursor.execute("SELECT movie_id, genre_id FROM movie_genres")
    data = cursor.fetchall()
    conn.close()

    movie_ids = list(set([row["movie_id"] for row in data]))
    genre_ids = list(set([row["genre_id"] for row in data]))

    movie_index = {m: i for i, m in enumerate(movie_ids)}
    genre_index = {g: i for i, g in enumerate(genre_ids)}

    matrix = np.zeros((len(movie_ids), len(genre_ids)))

    for row in data:
        matrix[movie_index[row["movie_id"]]][genre_index[row["genre_id"]]] = 1

    model = NearestNeighbors(metric="cosine")
    model.fit(matrix)


# --- UYGULAMA BAŞLANGICI ---
@app.on_event("startup")
def startup():
    build_knn()

# --- ENDPOINT'LER ---

@app.get("/")
def home():
    return {"status": "success", "message": "Movie Recommendation API is running"}

# 1. Film Listeleme
@app.get("/movies", summary="Film listesi", description="Popüler filmleri listeler")
def get_movies(limit: int = 20):
    conn = get_db()
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT id, title, vote_average, poster_path FROM movies LIMIT ?", (limit,))
        movies = cursor.fetchall()
        return [dict(movie) for movie in movies]
    finally:
        conn.close()

# 3. Filtreleme ve Sıralama
@app.get("/movies/filter",summary="Filtreleme ve Sıralama", description="Filmleri filtreleyerek sıralar")
def filter_movies(
    genre_id: Optional[int] = None,
    min_rating: float = 0,
    sort_by: str = "popularity"
):
    conn = get_db()
    try:
        cursor = conn.cursor()

        query = """
            SELECT m.id, m.title, m.vote_average, m.poster_path
            FROM movies m
        """
        params = []

        # Genre varsa JOIN ekle
        if genre_id is not None:
            query += """
                JOIN movie_genres mg ON m.id = mg.movie_id
                WHERE mg.genre_id = ? AND m.vote_average >= ?
            """
            params.extend([genre_id, min_rating])
        else:
            query += " WHERE m.vote_average >= ?"
            params.append(min_rating)

        # Sıralama kontrolü (güvenli)
        if sort_by == "rating":
            query += " ORDER BY m.vote_average DESC"
        else:
            query += " ORDER BY m.popularity DESC"

        query += " LIMIT 50"

        cursor.execute(query, params)
        movies = cursor.fetchall()

        return [dict(m) for m in movies]

    finally:
        conn.close()


# 2. Film Detay (Hata yönetimli ve doğru versiyon)
@app.get("/movies/{movie_id}", summary="Film Detay", description="Filmlerin detaylarını getirir")
def get_movie_detail(movie_id: int):
    conn = get_db()
    try:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT id, title, overview, vote_average, popularity, poster_path, backdrop_path 
            FROM movies WHERE id = ?
        """, (movie_id,))
        movie = cursor.fetchone()
        
        if not movie:
            raise HTTPException(status_code=404, detail="Film bulunamadı")
        
        return dict(movie)
    finally:
        conn.close()

@app.get("/user/{user_id}/memory-spheres", summary="Kullanıcının anı kürelerini (favori filmlerini) getir.", description="Kullanıcının favori filmlerini, türlerine göre atanmış özel renk ve duygu değerleriyle birlikte listeleyerek görsel bir (hafıza küresi) veri seti döndürür.")
def get_memory_spheres(user_id: int):
    conn = get_db()
    try:
        cursor = conn.cursor()
        # Öncelikli olarak GENRE_COLORS içindeki bir genre'ı al
        cursor.execute(f"""
            SELECT m.id, m.title, mg.genre_id
            FROM movies m
            JOIN favorites f ON m.id = f.movie_id
            JOIN movie_genres mg ON m.id = mg.movie_id
            WHERE f.user_id = ?
            ORDER BY CASE 
                {" ".join([f"WHEN mg.genre_id={gid} THEN 1" for gid in GENRE_COLORS.keys()])} 
                ELSE 2 END
            LIMIT 50
        """, (user_id,))
        
        favorites = cursor.fetchall()
        seen = set()
        spheres = []

        for fav in favorites:
            if fav["id"] in seen:
                continue
            seen.add(fav["id"])
            g_id = fav["genre_id"]
            info = GENRE_COLORS.get(g_id, {"color": "#FFFFFF", "emotion": "Nötr", "name": "Bilinmiyor"})
            spheres.append({
                "movie_id": fav["id"],
                "title": fav["title"],
                "color": info["color"],
                "emotion": info["emotion"],
                "genre_name": info["name"]
            })
        return spheres
    finally:
        conn.close()

# 5. Favoriye Ekleme (POST Metodu)
@app.post("/favorites/add", summary="Favoriye Ekleme", description="Kullanıcı bir filmi favorilere ekler")
def add_favorite(req: FavoriteRequest):
    conn = get_db()
    try:
        cursor = conn.cursor()
        cursor.execute("INSERT INTO favorites (user_id, movie_id) VALUES (?, ?)", (req.user_id, req.movie_id))
        conn.commit() # Veritabanına yazılması için ŞART
        return {"message": "Başarıyla favorilere eklendi"}
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=400, detail="Bu film zaten favorilerinizde")
    finally:
        conn.close()

# 6. Benzer Filmler
@app.get("/movies/{movie_id}/similar", summary="Benzer filmler öneren basit öneri algoritması", description="Girilen türe göre aynı türdeki filmler öneren algoritma")
def get_similar_movies(movie_id: int):
    conn = get_db()
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT genre_id FROM movie_genres WHERE movie_id = ? LIMIT 1", (movie_id,))
        genre = cursor.fetchone()
        
        if not genre:
            return []

        cursor.execute("""
            SELECT m.id, m.title, m.poster_path 
            FROM movies m
            JOIN movie_genres mg ON m.id = mg.movie_id
            WHERE mg.genre_id = ? AND m.id != ?
            ORDER BY m.popularity DESC LIMIT 6
        """, (genre[0], movie_id))
        
        return [dict(m) for m in cursor.fetchall()]
    finally:
        conn.close()


@app.get("/movies/{movie_id}/similar-ml", summary="Benzer filmler öneren ML", description="KNN algoritması kullanarak filme en benzer filmleri önerir")
def similar_movies_ml(movie_id: int):
    
    if movie_id not in movie_index:
        return []

    idx = movie_index[movie_id]

    distances, indices = model.kneighbors([matrix[idx]], n_neighbors=7)

    similar_ids = [
        movie_ids[i]
        for i in indices[0]
        if movie_ids[i] != movie_id
    ]

    conn = get_db()
    cursor = conn.cursor()

    results = []
    for sid in similar_ids:
        cursor.execute("SELECT id, title, poster_path FROM movies WHERE id = ?", (sid,))
        movie = cursor.fetchone()
        if movie:
            results.append(dict(movie))

    conn.close()
    return results


@app.get("/recommendations-ml/{user_id}", summary="Kullanıcı etkileşimine göre film önerisi", description="KNN algoritmasıyla kullanıcının favori filmlerine göre kişiselleştirilmiş öneri sunar ")
def recommend_movies_ml(user_id: int):
    
    conn = get_db()
    cursor = conn.cursor()

    cursor.execute("SELECT movie_id FROM favorites WHERE user_id = ?", (user_id,))
    favs = [row["movie_id"] for row in cursor.fetchall()]

    if not favs:
        return {"message": "Favori yok"}

    scores = {}

    for fav in favs:
        if fav not in movie_index:
            continue

        idx = movie_index[fav]

        distances, indices = model.kneighbors([matrix[idx]], n_neighbors=10)

        for i in indices[0]:
            mid = movie_ids[i]
            if mid in favs:
                continue

            scores[mid] = scores.get(mid, 0) + 1

    sorted_movies = sorted(scores.items(), key=lambda x: x[1], reverse=True)

    results = []
    for mid, _ in sorted_movies[:6]:
        cursor.execute("SELECT id, title, poster_path FROM movies WHERE id = ?", (mid,))
        movie = cursor.fetchone()
        if movie:
            results.append(dict(movie))

    conn.close()
    return results


@app.get("/user/{user_id}/emotion-profile", summary="Kullanıcı duygu proifili", description="Kullanıcının favori filmlerine göre duygu profili oluşturur")
def emotion_profile(user_id: int):
    conn = get_db()
    try:
        cursor = conn.cursor()

        cursor.execute("""
            SELECT mg.genre_id
            FROM favorites f
            JOIN movie_genres mg ON f.movie_id = mg.movie_id
            WHERE f.user_id = ?
        """, (user_id,))

        genres = cursor.fetchall()

        if not genres:
            return {"message": "Veri yok"}

        emotion_count = {}

        for g in genres:
            info = GENRE_COLORS.get(g["genre_id"])
            if not info:
                continue
            emotion = info["emotion"]
            emotion_count[emotion] = emotion_count.get(emotion, 0) + 1

        total = sum(emotion_count.values())

        profile = {
            e: round((c / total) * 100, 2)
            for e, c in emotion_count.items()
        }

        return profile

    finally:
        conn.close()


@app.get("/recommend-by-emotion/{user_id}", summary="Kullanıcının duygu profiline göre öneri", description="Kullanıncının duygu profiline göre aynı duyguda film önerisi sunar ")
def recommend_by_emotion(user_id: int):
    conn = get_db()
    cursor = conn.cursor()

    # 1. Kullanıcının favorileri
    cursor.execute("SELECT movie_id FROM favorites WHERE user_id = ?", (user_id,))
    favs = [row["movie_id"] for row in cursor.fetchall()]

    if not favs:
        return {"message": "Favori yok"}

    # 2. Duygu analizi (aynı mantık)
    cursor.execute("""
        SELECT mg.genre_id
        FROM favorites f
        JOIN movie_genres mg ON f.movie_id = mg.movie_id
        WHERE f.user_id = ?
    """, (user_id,))

    genres = cursor.fetchall()

    emotion_count = {}

    for g in genres:
        info = GENRE_COLORS.get(g["genre_id"])
        if not info:
            continue

        emotion = info["emotion"]
        emotion_count[emotion] = emotion_count.get(emotion, 0) + 1

    if not emotion_count:
        return {"message": "Duygu verisi yok"}

    # 3. En baskın duygu
    dominant_emotion = max(emotion_count, key=emotion_count.get)

    # 4. Bu duyguya karşılık gelen genre'lar
    target_genres = [
        gid for gid, val in GENRE_COLORS.items()
        if val["emotion"] == dominant_emotion
    ]

    # 5. ML ile öneri üret
    scores = {}

    for fav in favs:
        if fav not in movie_index:
            continue

        idx = movie_index[fav]

        distances, indices = model.kneighbors([matrix[idx]], n_neighbors=15)

        for i in indices[0]:
            mid = movie_ids[i]

            if mid in favs:
                continue

            scores[mid] = scores.get(mid, 0) + 1

    # 6. ML sonuçlarını sırala
    sorted_movies = sorted(scores.items(), key=lambda x: x[1], reverse=True)

    # 7. Duygu filtresi uygula
    filtered_results = []

    for mid, _ in sorted_movies:
        cursor.execute("""
            SELECT mg.genre_id
            FROM movie_genres mg
            WHERE mg.movie_id = ?
        """, (mid,))
        movie_genres = cursor.fetchall()

        genre_ids = [g["genre_id"] for g in movie_genres]

        # Eğer film hedef duyguya aitse ekle
        if any(g in target_genres for g in genre_ids):
            cursor.execute("SELECT id, title, poster_path FROM movies WHERE id = ?", (mid,))
            movie = cursor.fetchone()
            if movie:
                filtered_results.append(dict(movie))

        if len(filtered_results) == 6:
            break

    conn.close()

    return {
        "dominant_emotion": dominant_emotion,
        "recommendations": filtered_results
    }