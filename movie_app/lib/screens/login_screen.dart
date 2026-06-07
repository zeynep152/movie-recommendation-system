import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService _apiService = ApiService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  
  bool isLoginMode = true; 
  bool isLoading = false;

  void _handleAuth() async {
    setState(() => isLoading = true);
    
    if (isLoginMode) {
      // API üzerinden giriş isteği atılır
      final data = await _apiService.login(_emailController.text, _passwordController.text);
      if (data != null) {
        // SharedPreferences ve Singleton oturumu kaydedilir
        await UserSession().saveSession(data['user_id'], data['username']);
        if (mounted) Navigator.pop(context, true); 
      } else {
        _showSnackBar("E-posta veya şifre hatalı!");
      }
    } else {
      // API üzerinden kayıt isteği atılır
      bool success = await _apiService.register(
        _usernameController.text, _emailController.text, _passwordController.text
      );
      if (success) {
        setState(() => isLoginMode = true);
        _showSnackBar("Kayıt başarılı! Şimdi giriş yapabilirsiniz.");
      } else {
        _showSnackBar("Kayıt sırasında bir sorun oluştu.");
      }
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLoginMode ? "CINEMOD'a Giriş" : "Yeni Hesap")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const Icon(Icons.movie_filter, size: 80, color: Colors.amber),
              const SizedBox(height: 20),
              if (!isLoginMode) _buildField(_usernameController, "Kullanıcı Adı", Icons.person),
              const SizedBox(height: 15),
              _buildField(_emailController, "E-posta", Icons.email),
              const SizedBox(height: 15),
              _buildField(_passwordController, "Şifre", Icons.lock, obscure: true),
              const SizedBox(height: 30),
              isLoading 
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                      backgroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: _handleAuth,
                    child: Text(isLoginMode ? "GİRİŞ YAP" : "KAYIT OL", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
              TextButton(
                onPressed: () => setState(() => isLoginMode = !isLoginMode),
                child: Text(isLoginMode ? "Hesabın yok mu? Kayıt Ol" : "Zaten hesabın var mı? Giriş Yap"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.amber),
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFF1F1F1F),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}