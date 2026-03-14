from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel
import sqlite3
from typing import List, Optional

app = FastAPI(title="Movie Insight API", description="Inside Out Temalı Film Uygulaması Backend")

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

# --- ENDPOINT'LER ---

@app.get("/")
def home():
    return {"status": "success", "message": "Movie Recommendation API is running"}

# 1. Film Listeleme
@app.get("/movies")
def get_movies(limit: int = 20):
    conn = get_db()
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT id, title, vote_average, poster_path FROM movies LIMIT ?", (limit,))
        movies = cursor.fetchall()
        return [dict(movie) for movie in movies]
    finally:
        conn.close()

# 2. Film Detay (Hata yönetimli ve doğru versiyon)
@app.get("/movies/{movie_id}")
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

# 3. Filtreleme ve Sıralama
@app.get("/movies/filter")
def filter_movies(genre_id: Optional[int] = None, min_rating: float = 0, sort_by: str = "popularity"):
    conn = get_db()
    try:
        cursor = conn.cursor()
        query = "SELECT m.id, m.title, m.vote_average, m.poster_path FROM movies m"
        params = []

        if genre_id:
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

# 4. Inside Out - Hafıza Küreleri (Favoriler)
@app.get("/user/{user_id}/memory-spheres")
def get_memory_spheres(user_id: int):
    conn = get_db()
    try:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT m.id, m.title, mg.genre_id 
            FROM movies m
            JOIN favorites f ON m.id = f.movie_id
            JOIN movie_genres mg ON m.id = mg.movie_id
            WHERE f.user_id = ?
        """, (user_id,))
        favorites = cursor.fetchall()
        
        spheres = []
        for fav in favorites:
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
@app.post("/favorites/add")
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
            SELECT m.id, m.title, m.poster_path 
            FROM movies m
            JOIN movie_genres mg ON m.id = mg.movie_id
            WHERE mg.genre_id = ? AND m.id != ?
            ORDER BY m.popularity DESC LIMIT 6
        """, (genre[0], movie_id))
        
        return [dict(m) for m in cursor.fetchall()]
    finally:
        conn.close()