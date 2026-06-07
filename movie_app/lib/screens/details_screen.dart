import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';

class DetailsScreen extends StatelessWidget {
  final Movie movie;
  const DetailsScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    final ApiService api = ApiService();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: CustomScrollView(
        slivers: [
          // 1. BACKDROP (ÜST GENİŞ RESİM)
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    "https://image.tmdb.org/t/p/original${movie.backdropPath}",
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: Colors.grey.shade900),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xFF0A0A0A), Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. İÇERİK
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster ve Başlık Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          "https://image.tmdb.org/t/p/w300${movie.posterPath}",
                          width: 100, height: 150, fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(movie.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 5),
                            Text("(${movie.originalTitle})", style: const TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic)),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                _buildBadge(movie.releaseDate.split('-')[0], Colors.grey.shade900),
                                const SizedBox(width: 8),
                                _buildBadge(movie.originalLanguage.toUpperCase(), Colors.grey.shade900),
                                const SizedBox(width: 8),
                                _buildBadge("⭐ ${movie.voteAverage}", Colors.amber.shade900),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 35),

                  // 📊 İSTATİSTİKLER (TREND VE İZLEYİCİ)
                  Row(
                    children: [
                      _buildStatCard("Trend Skoru", movie.popularity.toInt().toString(), Icons.trending_up, Colors.blue),
                      const SizedBox(width: 15),
                      _buildStatCard("İzleyici", movie.voteCount.toString(), Icons.people, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 35),

                  // ÖZET
                  const Text("Özet", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber)),
                  const SizedBox(height: 10),
                  Text(movie.overview, style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5)),
                  const SizedBox(height: 40),

                  // AKSİYON BUTONLARI
                  _buildActionButtons(context, api),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: const Color(0xFF151515), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ApiService api) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, padding: const EdgeInsets.all(15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              if (!UserSession().isLoggedIn) return;
              bool s = await api.addToFavorites(UserSession().userId!, movie.id);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s ? "Eklendi! ✨" : "Zaten listede.")));
            },
            icon: const Icon(Icons.favorite),
            label: const Text("Favorilere Ekle"),
          ),
        ),
        const SizedBox(width: 15),
        Container(
          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
          child: IconButton(
            icon: const Icon(Icons.bookmark_add, color: Colors.white),
            padding: const EdgeInsets.all(15),
            onPressed: () async {
              if (!UserSession().isLoggedIn) return;
              bool s = await api.addToWatchlist(UserSession().userId!, movie.id);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s ? "İzleme listesinde! 🔖" : "Zaten listede.")));
            },
          ),
        ),
      ],
    );
  }
}