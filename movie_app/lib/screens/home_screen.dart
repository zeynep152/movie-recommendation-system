import 'package:flutter/material.dart';
import '../models/movie.dart'; 
import '../services/api_service.dart';
import 'details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Movie> allMovies = []; 
  List<Movie> displayedMovies = []; 
  bool isLoading = true;

  // Tasarım Renkleri
  final Color primaryColor = const Color(0xFFE5B9B5); // Rose Gold Aksan
  final Color scaffoldBg = const Color(0xFF0F0F1E);   // Derin Gece Mavisi
  final Color sapphireColor = const Color(0xFF16213E); // Üst Gradyan Rengi

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  void _fetchInitialData() async {
    try {
      final movies = await ApiService().fetchMovies();
      setState(() {
        allMovies = movies;
        displayedMovies = movies;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Hata: $e");
      setState(() => isLoading = false);
    }
  }

  void _filterMovies(String query) {
    setState(() {
      displayedMovies = allMovies
          .where((movie) => movie.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // Duyguya göre neon renk dönen yardımcı fonksiyon
  Color _getGlowColorByEmotion(String? emotion) {
    switch (emotion?.toLowerCase()) {
      case 'joy':
      case 'neşe':
        return const Color(0xFFFFD700); // Altın
      case 'sadness':
      case 'üzüntü':
        return const Color(0xFF4FACFE); // Mavi
      case 'anger':
      case 'öfke':
        return const Color(0xFFFF4B2B); // Kırmızı
      case 'fear':
      case 'korku':
        return const Color(0xFFA18CD1); // Mor
      default:
        return primaryColor; // Varsayılan Rose Gold
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: scaffoldBg,
      extendBodyBehindAppBar: true, 
      extendBody: true, 
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white12),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => _filterMovies(value),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Zihninde ne var? Ara...",
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: primaryColor, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: screenHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [sapphireColor, scaffoldBg],
          ),
        ),
        child: isLoading 
          ? Center(child: CircularProgressIndicator(color: primaryColor)) 
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 130), 
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25),
                    child: Text(
                      "Modunu Seç!",
                      style: TextStyle(
                        fontSize: 32, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white, 
                        height: 1.1,
                        letterSpacing: -0.5
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // --- MOOD PALETTE ---
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      children: [
                        _buildMoodSphere("Neşe", const Color(0xFFFFD700), Icons.wb_sunny_rounded),
                        _buildMoodSphere("Üzüntü", const Color(0xFF4FACFE), Icons.water_drop_rounded),                       
                        _buildMoodSphere("Öfke", const Color(0xFFFF4B2B), Icons.local_fire_department_rounded),
                        _buildMoodSphere("Korku", const Color(0xFFA18CD1), Icons.remove_red_eye_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 45),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Text(
                      _searchController.text.isEmpty ? "Senin İçin Seçtiklerimiz" : "Sonuçlar",
                      style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 25),
                  // --- MODERN YATAY LİSTE ---
                  SizedBox(
                    height: 360, 
                    child: displayedMovies.isEmpty 
                      ? const Center(child: Text("Bulunamadı.", style: TextStyle(color: Colors.white38)))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: displayedMovies.length,
                          itemBuilder: (context, index) {
                            final movie = displayedMovies[index];
                            // Filmin kendi duygusu yoksa index'e göre renk dağıtıyoruz (Görsel şölen için)
                            final Color currentGlow = _getGlowColorByEmotion(movie.dominantEmotion); 
                            
                            return Container(
                              width: 220, 
                              margin: const EdgeInsets.only(right: 25),
                              child: _buildMovieCard(movie, currentGlow),
                            );
                          },
                        ),
                  ),
                  const SizedBox(height: 120), 
                ],
              ),
            ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildMoodSphere(String label, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 68, height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, spreadRadius: 1),
              ],
              gradient: RadialGradient(
                colors: [color, color.withOpacity(0.5)],
                center: const Alignment(-0.2, -0.2),
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildMovieCard(Movie movie, Color glowColor) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsScreen(movie: movie))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(0.25),
                    blurRadius: 25,
                    spreadRadius: 2,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Hero(
                  tag: 'movieHero${movie.id}',
                  child: Image.network(
                    movie.posterPath, 
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              movie.title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Text(
              "Duygu Serisi",
              style: TextStyle(color: glowColor.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 95,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1E).withOpacity(0.92),
        border: const Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.white24,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore_rounded, size: 28), label: "Keşfet"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded, size: 28), label: "Profil"),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_motion_rounded, size: 28), label: "Arşiv"),
        ],
      ),
    );
  }
}