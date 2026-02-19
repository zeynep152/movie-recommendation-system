import requests
import json
import time
import os
from dotenv import load_dotenv

load_dotenv()

API_KEY = os.getenv("TMDB_API_KEY")
BASE_URL = "https://api.themoviedb.org/3"

all_movies = []

for page in range(1, 11):  # 1'den 10'a kadar
    print(f"Sayfa {page} çekiliyor...")

    url = f"{BASE_URL}/discover/movie"
    params = {
        "api_key": API_KEY,
        "language": "tr-TR",
        "page": page
    }

    response = requests.get(url, params=params)
    
    if response.status_code != 200:
        print("Hata oluştu:", response.status_code)
        break

    data = response.json()
    all_movies.extend(data["results"])

    time.sleep(0.2)  # Güvenli istek için küçük bekleme

# JSON dosyasına kaydet
with open("data/movies_200.json", "w", encoding="utf-8") as f:
        json.dump(all_movies, f, ensure_ascii=False, indent=4)

print("Toplam çekilen film sayısı:", len(all_movies))
print("İşlem tamamlandı ✅")