import 'package:flutter/material.dart';
import 'services/user_session.dart';
import 'screens/home_screen.dart'; 

void main() async {
  // 1. Flutter'ın sistem araçlarını (SharedPreferences, vb.) hazır hale getirir
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Not defterini oku: "Kayıtlı bir kullanıcı var mı?"
  // Bu işlem SharedPreferences kullanarak veriyi çeker.
  await UserSession().loadSession();

  // 3. Uygulamayı çalıştır
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CINEMOD',
      // Sağ üstteki 'Debug' bandını kaldırır, profesyonel görünüm sağlar
      debugShowCheckedModeBanner: false,
      
      // 🌟 Uygulama genelinde CINEMOD'un sinematik karanlık temasını uygular
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212), // Koyu arka plan
        primarySwatch: Colors.amber,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          elevation: 0,
        ),
      ),
      
      // Uygulama açıldığında ilk gideceği sayfa: HomeScreen
      home: const HomeScreen(),
    );
  }
}