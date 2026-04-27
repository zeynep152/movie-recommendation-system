from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import sqlite3
import hashlib
from typing import List, Optional
from sklearn.neighbors import NearestNeighbors
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.model_selection import train_test_split

app = FastAPI(
    title="Movie Recommendation API",
    description="Inside Out Temali Film Oneri Uygulamasi - Backend"
)

# --- CORS (Flutter/Web icin) ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- GLOBAL ML MODEL ---
model = None
matrix = None
movie_ids = None
movie_index = None

# --- VERITABANI ---
def get_db():
    conn = sqlite3.connect(r"database/movies.db")
    conn.row_factory = sqlite3.Row
    return conn

# --- MODELLER ---
class FavoriteRequest(BaseModel):
    user_id: int
    movie_id: int

class UserRegister(BaseModel):
    username: str
    email: str
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

class RatingRequest(BaseModel):
    user_id: int
    movie_id: int
    rating: int

# --- YARDIMCI ---
def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()

# --- GENISLETILMIS GENRE_COLORS ---
GENRE_COLORS = {
    28:    {"name": "Aksiyon",    "color": "#FF4500", "emotion": "Ofke"},
    35:    {"name": "Komedi",     "color": "#FFD700", "emotion": "Nese"},
    18:    {"name": "Dram",       "color": "#4169E1", "emotion": "Huzun"},
    10749: {"name": "Romantik",   "color": "#FF69B4", "emotion": "Sevgi"},
    27:    {"name": "Korku",      "color": "#800080", "emotion": "Korku"},
    53:    {"name": "Gerilim",    "color": "#8B0000", "emotion": "Korku"},
    878:   {"name": "Bilim Kurgu","color": "#00CED1", "emotion": "Merak"},
    12:    {"name": "Macera",     "color": "#FF8C00", "emotion": "Nese"},
    16:    {"name": "Animasyon",  "color": "#00FA9A", "emotion": "Nese"},
    14:    {"name": "Fantastik",  "color": "#9370DB", "emotion": "Merak"},
    80:    {"name": "Suc",        "color": "#2F4F4F", "emotion": "Ofke"},
}

# --- ML MODEL KURULUMU ---
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

@app.on_event("startup")
def startup():
    build_knn()

# ── FILMLER ──

@app.get("/")
def home():
    return {"status": "success", "message": "Movie Recommendation API is running"}

@app.get("/movies")
def get_movies(limit: int = 40, offset: int = 0):
    conn = get_db()
    try:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id, title, vote_average, poster_path, release_year FROM movies LIMIT ? OFFSET ?",
            (limit, offset)
        )
        return [dict(m) for m in cursor.fetchall()]
    finally:
        conn.close()

@app.get("/movies/filter")
def filter_movies(genre_id: Optional[int] = None, min_rating: float = 0, sort_by: str = "popularity"):
    conn = get_db()
    try:
        cursor = conn.cursor()
        query = "SELECT m.id, m.title, m.vote_average, m.poster_path, m.release_year FROM movies m"
        params = []
        if genre_id is not None:
            query += " JOIN movie_genres mg ON m.id = mg.movie_id WHERE mg.genre_id = ? AND m.vote_average >= ?"
            params.extend([genre_id, min_rating])
        else:
            query += " WHERE m.vote_average >= ?"
            params.append(min_rating)
        query += " ORDER BY m.vote_average DESC" if sort_by == "rating" else " ORDER BY m.popularity DESC"
        query += " LIMIT 50"
        cursor.execute(query, params)
        return [dict(m) for m in cursor.fetchall()]
    finally:
        conn.close()

@app.get("/movies/{movie_id}")
def get_movie_detail(movie_id: int):
    conn = get_db()
    try:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT id, title, overview, vote_average, popularity,
                   poster_path, backdrop_path, release_year FROM movies WHERE id = ?
        """, (movie_id,))
        movie = cursor.fetchone()
        if not movie:
            raise HTTPException(status_code=404, detail="Film bulunamadi")
        cursor.execute("""
            SELECT g.id, g.name FROM genres g
            JOIN movie_genres mg ON g.id = mg.genre_id WHERE mg.movie_id = ?
        """, (movie_id,))
        result = dict(movie)
        result["genres"] = [dict(g) for g in cursor.fetchall()]
        return result
    finally:
        conn.close()

# ── AUTH ──

@app.post("/users/register")
def register(req: UserRegister):
    conn = get_db()
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM users WHERE email = ?", (req.email,))
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="Bu e-posta zaten kayitli")
        cursor.execute(
            "INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)",
            (req.username, req.email, hash_password(req.password))
        )
        conn.commit()
        return {"message": "Kayit basarili", "user_id": cursor.lastrowid, "username": req.username}
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=400, detail="Kullanici adi zaten alinmis")
    finally:
        conn.close()

@app.post("/users/login")
def login(req: UserLogin):
    conn = get_db()
    try:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id, username, email FROM users WHERE email = ? AND password_hash = ?",
            (req.email, hash_password(req.password))
        )
        user = cursor.fetchone()
        if not user:
            raise HTTPException(status_code=401, detail="E-posta veya sifre hatali")
        return {"message": "Giris basarili", "user_id": user["id"],
                "username": user["username"], "email": user["email"]}
    finally:
        conn.close()

@app.get("/users/{user_id}")
def get_user(user_id: int):
    conn = get_db()
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT id, username, email, created_at FROM users WHERE id = ?", (user_id,))
        user = cursor.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="Kullanici bulunamadi")
        return dict(user)
    finally:
        conn.close()

# ── FAVORILER ──

@app.post("/favorites/add")
def add_favorite(req: FavoriteRequest):
    conn = get_db()
    try:
        cursor = conn.cursor()
        cursor.execute("INSERT INTO favorites (user_id, movie_id) VALUES (?, ?)",
                       (req.user_id, req.movie_id))
        conn.commit()
        return {"message": "Favoriye eklendi", "movie_id": req.movie_id}
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=400, detail="Bu film zaten favorilerinizde")
    finally:
        conn.close()

@app.delete("/favorites/remove")
def remove_favorite(user_id: int, movie_id: int):
    conn = get_db()
    try:
        cursor = conn.cursor()
        cursor.execute("DELETE FROM favorites WHERE user_id = ? AND movie_id = ?", (user_id, movie_id))
        conn.commit()
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Favori bulunamadi")
        return {"message": "Favoriden cikarildi", "movie_id": movie_id}
    finally:
        conn.close()

@app.get("/favorites/{user_id}")
def get_favorites(user_id: int):
    conn = get_db()
    try:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT m.id, m.title, m.poster_path, m.vote_average
            FROM movies m JOIN favorites f ON m.id = f.movie_id
            WHERE f.user_id = ? ORDER BY f.created_at DESC
        """, (user_id,))
        return [dict(m) for m in cursor.fetchall()]
    finally:
        conn.close()

# ── PUANLAMA ──

@app.post("/ratings")
def rate_movie(req: RatingRequest):
    if not 1 <= req.rating <= 5:
        raise HTTPException(status_code=400, detail="Puan 1-5 arasinda olmali")
    conn = get_db()
    try:
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO rating (user_id, movie_id, rating) VALUES (?, ?, ?)
            ON CONFLICT(user_id, movie_id) DO UPDATE SET rating = excluded.rating
        """, (req.user_id, req.movie_id, req.rating))
        conn.commit()
        return {"message": "Puan kaydedildi", "rating": req.rating}
    finally:
        conn.close()

@app.get("/ratings/{user_id}/{movie_id}")
def get_rating(user_id: int, movie_id: int):
    conn = get_db()
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT rating FROM rating WHERE user_id = ? AND movie_id = ?", (user_id, movie_id))
        row = cursor.fetchone()
        return {"rating": row["rating"] if row else None}
    finally:
        conn.close()

# ── ML ONERILERI ──

@app.get("/movies/{movie_id}/similar")
def get_similar_movies(movie_id: int):
    conn = get_db()
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT genre_id FROM movie_genres WHERE movie_id = ? LIMIT 1", (movie_id,))
        genre = cursor.fetchone()
        if not genre:
            return []
        cursor.execute("""
            SELECT m.id, m.title, m.poster_path FROM movies m
            JOIN movie_genres mg ON m.id = mg.movie_id
            WHERE mg.genre_id = ? AND m.id != ? ORDER BY m.popularity DESC LIMIT 6
        """, (genre[0], movie_id))
        return [dict(m) for m in cursor.fetchall()]
    finally:
        conn.close()

@app.get("/movies/{movie_id}/similar-ml")
def similar_movies_ml(movie_id: int):
    if movie_id not in movie_index:
        return []
    idx = movie_index[movie_id]
    distances, indices = model.kneighbors([matrix[idx]], n_neighbors=7)
    similar_ids = [movie_ids[i] for i in indices[0] if movie_ids[i] != movie_id]
    conn = get_db()
    cursor = conn.cursor()
    results = []
    for sid in similar_ids:
        cursor.execute("SELECT id, title, poster_path, vote_average FROM movies WHERE id = ?", (sid,))
        movie = cursor.fetchone()
        if movie:
            results.append(dict(movie))
    conn.close()
    return results

@app.get("/recommendations-ml/{user_id}")
def recommend_movies_ml(user_id: int):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT movie_id FROM favorites WHERE user_id = ?", (user_id,))
    favs = [row["movie_id"] for row in cursor.fetchall()]
    if not favs:
        cursor.execute("SELECT id, title, poster_path, vote_average FROM movies ORDER BY popularity DESC LIMIT 6")
        result = [dict(m) for m in cursor.fetchall()]
        conn.close()
        return {"type": "popular", "recommendations": result}
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
        cursor.execute("SELECT id, title, poster_path, vote_average FROM movies WHERE id = ?", (mid,))
        movie = cursor.fetchone()
        if movie:
            results.append(dict(movie))
    conn.close()
    return {"type": "personalized", "recommendations": results}

# ── DUYGU SISTEMI ──

@app.get("/user/{user_id}/emotion-profile")
def emotion_profile(user_id: int):
    conn = get_db()
    try:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT mg.genre_id FROM favorites f
            JOIN movie_genres mg ON f.movie_id = mg.movie_id WHERE f.user_id = ?
        """, (user_id,))
        genres = cursor.fetchall()
        if not genres:
            return {"message": "Favori film eklenmemis", "profile": {}}
        emotion_count = {}
        for g in genres:
            info = GENRE_COLORS.get(g["genre_id"])
            if not info:
                continue
            e = info["emotion"]
            emotion_count[e] = emotion_count.get(e, 0) + 1
        total = sum(emotion_count.values())
        if total == 0:
            return {"message": "Duygu verisi hesaplanamadi", "profile": {}}
        profile = {e: round((c / total) * 100, 1) for e, c in sorted(emotion_count.items(), key=lambda x: x[1], reverse=True)}
        return {"dominant_emotion": max(emotion_count, key=emotion_count.get), "profile": profile}
    finally:
        conn.close()

@app.get("/user/{user_id}/memory-spheres")
def get_memory_spheres(user_id: int):
    conn = get_db()
    try:
        cursor = conn.cursor()
        cursor.execute(f"""
            SELECT m.id, m.title, m.poster_path, mg.genre_id FROM movies m
            JOIN favorites f ON m.id = f.movie_id
            JOIN movie_genres mg ON m.id = mg.movie_id WHERE f.user_id = ?
            ORDER BY CASE {" ".join([f"WHEN mg.genre_id={gid} THEN 1" for gid in GENRE_COLORS.keys()])} ELSE 2 END LIMIT 50
        """, (user_id,))
        favorites = cursor.fetchall()
        seen = set()
        spheres = []
        for fav in favorites:
            if fav["id"] in seen:
                continue
            seen.add(fav["id"])
            info = GENRE_COLORS.get(fav["genre_id"], {"color": "#AAAAAA", "emotion": "Notr", "name": "Diger"})
            spheres.append({
                "movie_id": fav["id"], "title": fav["title"],
                "poster_path": fav["poster_path"],
                "color": info["color"], "emotion": info["emotion"], "genre_name": info["name"]
            })
        return spheres
    finally:
        conn.close()

@app.get("/recommend-by-emotion/{user_id}")
def recommend_by_emotion(user_id: int):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT movie_id FROM favorites WHERE user_id = ?", (user_id,))
    favs = [row["movie_id"] for row in cursor.fetchall()]
    if not favs:
        return {"message": "Favori film eklenmemis"}
    cursor.execute("""
        SELECT mg.genre_id FROM favorites f JOIN movie_genres mg ON f.movie_id = mg.movie_id WHERE f.user_id = ?
    """, (user_id,))
    emotion_count = {}
    for g in cursor.fetchall():
        info = GENRE_COLORS.get(g["genre_id"])
        if not info:
            continue
        e = info["emotion"]
        emotion_count[e] = emotion_count.get(e, 0) + 1
    if not emotion_count:
        return {"message": "Duygu verisi hesaplanamadi"}
    dominant_emotion = max(emotion_count, key=emotion_count.get)
    target_genres = [gid for gid, val in GENRE_COLORS.items() if val["emotion"] == dominant_emotion]
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
    sorted_movies = sorted(scores.items(), key=lambda x: x[1], reverse=True)
    filtered_results = []
    for mid, _ in sorted_movies:
        cursor.execute("SELECT mg.genre_id FROM movie_genres mg WHERE mg.movie_id = ?", (mid,))
        movie_genre_ids = [g["genre_id"] for g in cursor.fetchall()]
        if any(g in target_genres for g in movie_genre_ids):
            cursor.execute("SELECT id, title, poster_path, vote_average FROM movies WHERE id = ?", (mid,))
            movie = cursor.fetchone()
            if movie:
                filtered_results.append(dict(movie))
        if len(filtered_results) == 6:
            break
    conn.close()
    return {
        "dominant_emotion": dominant_emotion,
        "target_genres": [GENRE_COLORS[g]["name"] for g in target_genres if g in GENRE_COLORS],
        "recommendations": filtered_results
    }

@app.get("/model-comparison")
def compare_models():
    X_train, X_test = train_test_split(matrix, test_size=0.2, random_state=42)
    knn = NearestNeighbors(metric="cosine")
    knn.fit(X_train)
    def p_knn(k=5):
        scores = []
        for i in range(len(X_test)):
            _, indices = knn.kneighbors([X_test[i]], n_neighbors=k)
            correct = sum(1 for idx in indices[0] if cosine_similarity([X_test[i]], [X_train[idx]])[0][0] > 0.5)
            scores.append(correct / k)
        return sum(scores) / len(scores)
    def p_cos(k=5):
        scores = []
        for i in range(len(X_test)):
            sims = cosine_similarity([X_test[i]], X_train)[0]
            top = np.argsort(sims)[-k:]
            scores.append(sum(1 for idx in top if sims[idx] > 0.5) / k)
        return sum(scores) / len(scores)
    ks, cs = p_knn(), p_cos()
    return {"KNN Precision@5": round(ks, 3), "Cosine Precision@5": round(cs, 3),
            "best_model": "KNN" if ks >= cs else "Cosine"}