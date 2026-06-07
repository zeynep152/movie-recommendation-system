import sqlite3

# Veritabanı dosyanın yolu (backend içinden bir üst klasöre çıkıp database klasörüne bakıyor)
DB_PATH = "../database/movies.db"

def get_db():
    conn = sqlite3.connect(DB_PATH)
    # Row_factory: Verilerin ID, Başlık gibi isimlerle (sözlük yapısında) gelmesini sağlar.
    conn.row_factory = sqlite3.Row
    return conn