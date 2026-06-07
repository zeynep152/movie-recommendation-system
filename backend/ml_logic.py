import numpy as np
from sklearn.neighbors import NearestNeighbors
from db_connection import get_db

class MLManager:
    def __init__(self):
        self.model = None
        self.matrix = None
        self.movie_ids = None
        self.movie_index = None

    def build_knn(self):
        """kNN modelini veritabanındaki film türlerine göre eğitir."""
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute("SELECT movie_id, genre_id FROM movie_genres")
        data = cursor.fetchall()
        conn.close()

        if not data:
            return

        self.movie_ids = list(set([row["movie_id"] for row in data]))
        genre_ids = list(set([row["genre_id"] for row in data]))
        self.movie_index = {m: i for i, m in enumerate(self.movie_ids)}
        genre_index = {g: i for i, g in enumerate(genre_ids)}

        # Filmleri ve türleri temsil eden matris (Vektörizasyon)
        self.matrix = np.zeros((len(self.movie_ids), len(genre_ids)))
        for row in data:
            self.matrix[self.movie_index[row["movie_id"]]][genre_index[row["genre_id"]]] = 1

        # Cosine benzerliği kullanarak en yakın komşuları bulan model
        self.model = NearestNeighbors(metric="cosine")
        self.model.fit(self.matrix)

# Tek bir global instance oluşturuyoruz
ml_manager = MLManager()