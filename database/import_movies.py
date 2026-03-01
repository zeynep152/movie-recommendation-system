import json
import sqlite3

conn = sqlite3.connect("database/movies.db")
cursor = conn.cursor()

# JSON'u aç
with open("data/movies.json", "r", encoding="utf-8") as f:
    movies = json.load(f)

for movie in movies:
    release_year = None
    if movie.get("release_date"):
        release_year = movie["release_date"][:4]

    cursor.execute("""
        INSERT OR IGNORE INTO movies (
        id, title, original_title, overview,
        release_date, release_year,
        original_language, vote_average, vote_count,
        popularity, adult, video,
        poster_path, backdrop_path
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
""", (
        movie.get("id"),
        movie.get("title"),
        movie.get("original_title"),
        movie.get("overview"),
        movie.get("release_date"),
        release_year,
        movie.get("original_language"),
        movie.get("vote_average"),
        movie.get("vote_count"),
        movie.get("popularity"),
        movie.get("adult"),
        movie.get("video"),
        movie.get("poster_path"),
        movie.get("backdrop_path")
    ))

    for genre_id in movie.get("genre_ids", []):
        cursor.execute("""
            INSERT OR IGNORE INTO movie_genres VALUES (?, ?)
        """, (movie.get("id"), genre_id))

conn.commit()
conn.close()

print("Movies imported successfully.")