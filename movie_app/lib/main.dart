import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
// Yeni sayfaları oluşturduğunda buraya import etmeyi unutma:
// import 'screens/mood_screen.dart';
// import 'screens/profile_screen.dart';

void main() {
  runApp(const MovieApp());
}

class MovieApp extends StatelessWidget {
  const MovieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inside Up',
      debugShowCheckedModeBanner: false,
      // --- TEMA AYARLARI BURADA BAŞLIYOR ---
      theme: ThemeData(
        useMaterial3: true,
        // Ana renk tohumu (Rose Gold)
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE5B9B5),
          primary: const Color(0xFFE5B9B5),
          surface: const Color(0xFFFFF9F9), // Sayfa arka plan rengi
          onSurface: const Color(0xFF8E6E6E), // Yazı rengi
        ),
        // Scaffold arka planını sabitleyelim
        scaffoldBackgroundColor: const Color(0xFFFFF9F9),
        // AppBar teması
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFF9F9),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF8E6E6E)),
          centerTitle: true,
        ),
      ),
      home: HomeScreen(),
    );
  }
}
class MainNavigationScreen extends StatefulWidget {
  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // Sayfalar arası geçiş listesi
  final List<Widget> _pages = [
    HomeScreen(), // Senin mevcut 18 (veya 100) filmlik keşfet sayfan
    PlaceholderScreen(title: "Duygu Profili", icon: Icons.psychology, color: Colors.purple), 
    PlaceholderScreen(title: "Profil", icon: Icons.person, color: Colors.orange),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Sayfayı değiştirir ve anında ekrana yansıtır (Hot Reload dostudur)
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Seçili sayfayı ekrana getirir
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.indigo,
        type: BottomNavigationBarType.fixed, // 3'ten fazla menü olursa kaymayı engeller
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Keşfet'),
          BottomNavigationBarItem(icon: Icon(Icons.bubble_chart), label: 'Duygu'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profil'),
        ],
      ),
    );
  }
}

// Yeni sayfaları henüz oluşturmadığın için hata almamak adına bu geçici sınıfı kullanıyoruz
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  PlaceholderScreen({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: color),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 100, color: color.withOpacity(0.5)),
            SizedBox(height: 20),
            Text("$title Sayfası Çok Yakında!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text("KNN sonuçlarıyla entegre edilecektir.", textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}