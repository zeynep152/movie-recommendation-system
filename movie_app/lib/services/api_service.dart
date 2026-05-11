import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class ApiService {
  // ÖNEMLİ: Android emülatöründen bilgisayardaki localhost'a erişmek için 10.0.2.2 kullanılır.
//  final String baseUrl = "http://192.168.1.35:8000"; // 10.0.2.2 yerine bunu yaz
  final String baseUrl = "http://10.0.2.2:8000";
  Future<List<Movie>> fetchMovies() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/movies"));
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        return data.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception("Filmler yüklenemedi: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Bağlantı hatası: $e");
    }
  }
}