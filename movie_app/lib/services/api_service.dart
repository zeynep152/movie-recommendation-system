import 'dart:convert';
import 'dart:io'; // Platform tespiti için gerekli
import 'package:flutter/foundation.dart'; // kIsWeb kontrolü için gerekli
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class ApiService {
  // 🌟 DİNAMİK URL TESPİTİ
  // Bu fonksiyon uygulamanın çalıştığı yere göre doğru adresi seçer.
  String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:8000"; // Tarayıcı için
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:8000"; // Android Emülatör için bilgisayar adresi
    } else {
      return "http://127.0.0.1:8000"; // iOS veya diğerleri için
    }
  }

  // Popüler Filmleri Getir
  Future<List<Movie>> fetchPopularMovies() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/movies/lists/popular"));
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        return data.map((item) => Movie.fromJson(item)).toList();
      }
    } catch (e) {
      print("Popüler filmler çekilemedi: $e");
    }
    return [];
  }

  // En Yüksek Puanlı Filmleri Getir
  Future<List<Movie>> fetchTopRatedMovies() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/movies/lists/top-rated"));
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        return data.map((item) => Movie.fromJson(item)).toList();
      }
    } catch (e) {
      print("Puanlı filmler çekilemedi: $e");
    }
    return [];
  }

  // Mod (Inside Out) Filmlerini Getir
  Future<Map<String, dynamic>> fetchMoodMovies() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/movies/lists/mood-esintisi"));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Mod filmleri çekilemedi: $e");
    }
    return {"mood_name": "Belirsiz", "emotion": "Nötr", "movies": []};
  }

  // 🌟 YAPAY ZEKA ÖNERİLERİNİ GETİR (kNN Modeli)
  Future<List<Movie>> fetchAIRecommendations(int userId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/recommendations/$userId"));
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        return data.map((item) => Movie.fromJson(item)).toList();
      }
    } catch (e) {
      print("AI Önerileri çekilemedi: $e");
    }
    return [];
  }

  // Film Arama
  Future<List<Movie>> searchMovies(String query) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/search?query=$query"));
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        return data.map((item) => Movie.fromJson(item)).toList();
      }
    } catch (e) {
      print("Arama hatası: $e");
    }
    return [];
  }

  // FAVORİYE EKLEME (Detay sayfasından çağrılacak)
  Future<bool> addToFavorites(int userId, int movieId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/favorites/add"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"user_id": userId, "movie_id": movieId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Favorileri Getir
  Future<List<Movie>> getFavorites(int userId) async {
    final response = await http.get(Uri.parse("$baseUrl/favorites/$userId"));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((item) => Movie.fromJson(item)).toList();
    }
    return [];
  }

  // İzleme listesini getir
  Future<List<Movie>> fetchWatchlist(int userId) async {
    final response = await http.get(Uri.parse("$baseUrl/watchlist/$userId"));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((item) => Movie.fromJson(item)).toList();
    }
    return [];
  }

  // İzleme listesine film ekle
  Future<bool> addToWatchlist(int userId, int movieId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/watchlist/add"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"user_id": userId, "movie_id": movieId}),
    );
    return response.statusCode == 200;
  }

  //  KULLANICI GİRİŞİ (Login)
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/users/login"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"email": email, "password": password}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Giriş sırasında hata: $e");
    }
    return null;
  }

  // KULLANICI KAYDI (Register)
  Future<bool> register(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/users/register"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "username": username,
          "email": email,
          "password": password
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Kayıt sırasında hata: $e");
      return false;
    }
  }
}