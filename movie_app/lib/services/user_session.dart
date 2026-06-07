import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  // Singleton yapısı: Uygulama boyunca bu sınıftan sadece tek bir nesne üretilmesini sağlar.
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  int? userId;
  String? username;
  bool isLoggedIn = false;

  // 1. OTURUMU KAYDET: Giriş başarılı olduğunda bu fonksiyonu çağıracağız.
  Future<void> saveSession(int id, String name) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', id);
    await prefs.setString('username', name);
    await prefs.setBool('isLoggedIn', true);

    userId = id;
    username = name;
    isLoggedIn = true;
  }

  // 2. OTURUMU YÜKLE: Uygulama her ilk açıldığında 'main.dart' içinde bunu çağıracağız.
  Future<void> loadSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId');
    username = prefs.getString('username');
    isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  }

  // 3. OTURUMU SİL (LOGOUT): Çıkış yapıldığında hafızayı temizler.
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hafızadaki her şeyi siler.
    
    userId = null;
    username = null;
    isLoggedIn = false;
  }
}