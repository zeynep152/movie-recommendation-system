import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/movie.dart';
import '../services/user_session.dart';
import '../services/api_service.dart';
import 'login_screen.dart'; // Ayrı dosyada duran giriş ekranı
import 'details_screen.dart'; // Kartlara tıklanınca detay sayfasına gitmek için

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  
  // Sayfa Durum Değişkenleri
  bool isLoading = false;  // Yüklenme animasyonu kontrolü
  List<Movie> favoriteMovies = []; // Kullanıcının favori filmleri
  List<Movie> watchlistMovies = []; // 🌟 YENİ: Kullanıcının izleme listesindeki filmler
  Map<String, dynamic> stats = {}; // Duygu analizi istatistikleri

  @override
  void initState() {
    super.initState();
    // Eğer kullanıcı zaten giriş yapmışsa direkt profil verilerini yükle
    if (UserSession().isLoggedIn) {
      _loadProfileData();
    }
  }

  // --- VERİ ÇEKME FONKSİYONLARI ---

  // Favorileri, İzleme Listesini ve Duygu İstatistiklerini Getirir
  void _loadProfileData() async {
    setState(() => isLoading = true);
    final userId = UserSession().userId;
    final baseUrl = _apiService.baseUrl; // ApiService'den dinamik IP/URL adresini alır

    try {
      // 🌟 PERFORMANS OPTİMİZASYONU: İstekleri paralel atarak sayfa açılışını hızlandırıyoruz
      final results = await Future.wait<dynamic>([
        _apiService.getFavorites(userId!),
        _apiService.fetchWatchlist(userId),
        http.get(Uri.parse("$baseUrl/user/$userId/emotion-profile")),
      ]);

      final favList = results[0] as List<Movie>;
      final watchList = results[1] as List<Movie>;
      final statsResp = results[2] as http.Response;

      setState(() {
        favoriteMovies = favList;
        watchlistMovies = watchList;
        if (statsResp.statusCode == 200) {
          final Map<String, dynamic> statsData = json.decode(statsResp.body);
          stats = statsData['profile'] ?? {};
        }
      });
    } catch (e) {
      _showSnackBar("Veriler güncellenirken hata oluştu.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Çıkış Yapma İşlemi
  void _handleLogout() async {
    await UserSession().logout(); // Hafızayı temizler
    setState(() {
      favoriteMovies = [];
      watchlistMovies = []; // 🌟 İzleme listesini de temizle
      stats = {};
    });
  }

  // --- ARAYÜZ (UI) BÖLÜMLERİ ---

  @override
  Widget build(BuildContext context) {
    // Eğer giriş yapılmamışsa şık Giriş Çağrısını, yapılmışsa tam istediğin Profil Görünümünü göster
    return Scaffold(
      appBar: AppBar(
        title: Text(UserSession().isLoggedIn ? "Profilim" : "Giriş Yap"),
        actions: [
          if (UserSession().isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: _handleLogout,
              tooltip: "Çıkış Yap",
            )
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.amber)) 
        : UserSession().isLoggedIn ? _buildProfileView() : _buildLoginPrompt(),
    );
  }

  // Giriş Yapılmadığında Gösterilecek Şık Ekran
  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle_outlined, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            "Profilinizi yönetmek için giriş yapın", 
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
              if (result == true) {
                _loadProfileData();
              }
            },
            child: const Text("Giriş Yap / Kayıt Ol"),
          ),
        ],
      ),
    );
  }

  // Orijinal Profil Ekranı Tasarımı
  Widget _buildProfileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Merhaba, ${UserSession().username}!", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 25),
          const Text("Duygu Profilin", style: TextStyle(fontSize: 18, color: Colors.amber)),
          const SizedBox(height: 10),
          _buildEmotionStats(), // Kutulu istatistik grafiği
          const SizedBox(height: 30),
          const Text("Favori Filmlerin", style: TextStyle(fontSize: 18, color: Colors.amber)),
          const SizedBox(height: 10),
          _buildFavoritesList(), // Dikey kart listesi tasarımı
          const SizedBox(height: 30),
          // 🌟 YENİ: İzleme Listesi Başlığı ve Widget Çağrısı
          const Text("İzleme Listen", style: TextStyle(fontSize: 18, color: Colors.amber)),
          const SizedBox(height: 10),
          _buildWatchlist(), // Favorilerle aynı dikey tasarımda İzleme Listesi
        ],
      ),
    );
  }

  // Duygu Grafiği (LinearProgressIndicator ile)
  Widget _buildEmotionStats() {
    if (stats.isEmpty) {
      return const Text(
        "Analiz için yeterli veri yok. Filmleri favorilerine ekleyerek duygu profilini oluşturabilirsin!",
        style: TextStyle(color: Colors.grey, fontSize: 14),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: stats.entries.map((e) {
          double val = (e.value as num).toDouble() / 100;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text("%${(val * 100).toInt()}", style: TextStyle(color: _getEmotionColor(e.key), fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: val,
                    color: _getEmotionColor(e.key),
                    backgroundColor: Colors.white10,
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Duygu isimlerine göre Inside Out renklerini döndüren yardımcı fonksiyon
  Color _getEmotionColor(String emotion) {
    switch (emotion) {
      case 'Neşe': return Colors.yellow;
      case 'Hüzün': return Colors.blue;
      case 'Öfke': return Colors.redAccent;
      case 'Korku': return Colors.purple;
      case 'Sevgi': return Colors.pinkAccent;
      case 'Merak': return Colors.cyanAccent;
      default: return Colors.amber;
    }
  }

  // Favori Filmler Listesi
  Widget _buildFavoritesList() {
    if (favoriteMovies.isEmpty) return const Text("Henüz favori film eklemedin.", style: TextStyle(color: Colors.grey, fontSize: 14));
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: favoriteMovies.length,
      itemBuilder: (context, index) {
        final movie = favoriteMovies[index];
        return Card(
          color: const Color(0xFF1F1F1F),
          child: ListTile(
            leading: movie.posterPath.isNotEmpty
                ? Image.network("https://image.tmdb.org/t/p/w200${movie.posterPath}", width: 50, fit: BoxFit.cover)
                : const Icon(Icons.movie, size: 50),
            title: Text(movie.title),
            subtitle: Text("Puan: ${movie.voteAverage}"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DetailsScreen(movie: movie)),
              );
            },
          ),
        );
      },
    );
  }

  // 🌟 YENİ: İzleme Listesi Görünümü (Favoriler Listesi ile Birebir Aynı Tasarım)
  Widget _buildWatchlist() {
    if (watchlistMovies.isEmpty) return const Text("İzleme listenizde film bulunmuyor.", style: TextStyle(color: Colors.grey, fontSize: 14));
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: watchlistMovies.length,
      itemBuilder: (context, index) {
        final movie = watchlistMovies[index];
        return Card(
          color: const Color(0xFF1F1F1F),
          child: ListTile(
            leading: movie.posterPath.isNotEmpty
                ? Image.network("https://image.tmdb.org/t/p/w200${movie.posterPath}", width: 50, fit: BoxFit.cover)
                : const Icon(Icons.movie, size: 50),
            title: Text(movie.title),
            subtitle: Text("Puan: ${movie.voteAverage}"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DetailsScreen(movie: movie)),
              );
            },
          ),
        );
      },
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}