import sqlite3

conn = sqlite3.connect("database/movies.db")
cursor = conn.cursor()

with open("database/schema.sql", "r", encoding="utf-8") as f:
    schema = f.read()

cursor.executescript(schema)

conn.commit()
conn.close()

print("Database created succesfully.")
