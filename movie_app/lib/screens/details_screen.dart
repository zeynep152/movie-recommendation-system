import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/movie.dart';

class DetailsScreen extends StatelessWidget {
  final Movie movie;

  DetailsScreen({required this.movie});

  // Favoriye ekleme fonksiyonu
  Future<void> addToFavorites(BuildContext context) async {
    final url = Uri.parse("http://10.0.2.2:8000/favorites/add");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_id": 1, // Şimdilik test için manuel 1 veriyoruz
          "movie_id": movie.id
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Favoriye Eklendi! 🌟")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bu film zaten mevcut.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bağlantı hatası!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(movie.title)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Hero(
              tag: 'movieHero${movie.id}', // HomeScreen'deki ile birebir aynı olmalı
              child: Image.network(
                movie.posterPath, 
                width: double.infinity, 
                height: 450, 
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(movie.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.amber),
                      Text(" ${movie.voteAverage} / 10", style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => addToFavorites(context),
                    icon: Icon(Icons.auto_awesome, color: Colors.amber),
                    label: Text("Hafıza Küresi Olarak Arşivle"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE0C097),
                      foregroundColor: Colors.black87,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}