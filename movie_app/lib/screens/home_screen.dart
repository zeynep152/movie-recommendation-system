import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../models/movie.dart';
import 'details_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final ApiService _apiService = ApiService();

  // Sayfalar arası geçiş için liste
  final List<Widget> _pages = [
    const MovieDiscoverPage(),
    const Center(child: Text("Arşiv Sayfası (Yapım Aşamasında)")),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack: Sayfalar arası geçişte verilerin kaybolmamasını sağlar.
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1F1F1F),
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Arşiv'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

// --- ANA KEŞİF SAYFASI (Film Listeleri Burada) ---
class MovieDiscoverPage extends StatefulWidget {
  const MovieDiscoverPage({super.key});

  @override
  State<MovieDiscoverPage> createState() => _MovieDiscoverPageState();
}

class _MovieDiscoverPageState extends State<MovieDiscoverPage> {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
            children: [
              TextSpan(text: 'CINE', style: TextStyle(color: Colors.white)),
              TextSpan(text: 'MOD', style: TextStyle(color: Colors.amber)),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. MOD ESİNTİSİ (Inside Out Bölümü)
            _buildMoodSection(),

            const SizedBox(height: 20),
            
            // 2. YAPAY ZEKA ÖNERİLERİ (Projenin Kalbi)
            _buildAISection(),

            const SizedBox(height: 20),

            // 3. POPÜLER FİLMLER
            _buildSectionTitle("🔥 Popüler Filmler"),
            _buildMovieHorizontalList(_apiService.fetchPopularMovies()),

            const SizedBox(height: 20),

            // 4. EN YÜKSEK PUANLILAR
            _buildSectionTitle("🏆 En Yüksek Puanlılar"),
            _buildMovieHorizontalList(_apiService.fetchTopRatedMovies()),
          ],
        ),
      ),
    );
  }

  // --- WIDGETLAR ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  // Yatay Film Listesi Oluşturucu (Hata aldığın yer burasıydı, düzeltildi)
  Widget _buildMovieHorizontalList(Future<List<Movie>> future) {
    return FutureBuilder<List<Movie>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(height: 50, child: Center(child: Text("Veri yüklenemedi.")));
        }

        final movies = snapshot.data!;
        return SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsScreen(movie: movie))),
                child: Container(
                  width: 130,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            "https://image.tmdb.org/t/p/w500${movie.posterPath}",
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: Colors.grey, child: const Icon(Icons.movie)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(movie.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Yapay Zeka Bölümü
  Widget _buildAISection() {
    if (!UserSession().isLoggedIn) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.amber)),
        child: const Row(
          children: [
            Icon(Icons.psychology, color: Colors.amber, size: 40),
            SizedBox(width: 15),
            Expanded(child: Text("Giriş yaparak favorilerine göre eğitilen AI önerilerini görebilirsin!", style: TextStyle(fontSize: 14))),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("✨ Senin İçin AI Önerileri"),
        _buildMovieHorizontalList(_apiService.fetchAIRecommendations(UserSession().userId!)),
      ],
    );
  }

  // Mod Esintisi Bölümü
  Widget _buildMoodSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _apiService.fetchMoodMovies(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final moodName = snapshot.data!['mood_name'];
        final moviesRaw = snapshot.data!['movies'] as List;
        final movies = moviesRaw.map((e) => Movie.fromJson(e)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("🌈 Mod Esintisi: $moodName"),
            _buildMovieHorizontalList(Future.value(movies)),
          ],
        );
      },
    );
  }
}