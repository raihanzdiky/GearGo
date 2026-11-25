import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../widgets/toast_helper.dart';
import 'register_screen.dart';
import 'main_navigation.dart';
import 'owner_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final user = await DatabaseHelper.instance.loginUser(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (user != null) {
        DatabaseHelper.currentUser = user;
        // Routing otomatis berdasarkan aktor (Owner atau Customer)
        if (user.role == 'owner') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const OwnerDashboardScreen(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigation()),
          );
        }
      } else {
        ToastHelper.show(
          context,
          'Email atau Password salah!',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // BAGIAN ATAS: Gambar Ilustrasi Asli dengan Lengkungan Bawah
            Stack(
              children: [
                ClipPath(
                  clipper: _WaveBottomClipper(),
                  child: Container(
                    width: double.infinity,
                    // Warna latar hijau tua menyatu dengan bagian atas banner jika ada sisa ruang
                    color: const Color(0xFF153B24),
                    child: Image.asset(
                      'assets/images/login_banner.jpg',
                      width: double.infinity,
                      fit: BoxFit.fitWidth, // Menampilkan seluruh lebar gambar tanpa memotong sisi kiri/kanan
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 220,
                          color: const Color(0xFF1B4328),
                          alignment: Alignment.center,
                          child: const Text(
                            'Pastikan assets/images/login_banner.jpg tersedia',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Header Teks "GearGo" di Kiri & Logo di Kanan Atas
                // (Hapus blok SafeArea di bawah ini jika gambar ilustrasi kalian
                // sudah memiliki tulisan "GearGo" dan logo di dalamnya)
              ],
            ),

            // BAGIAN BAWAH: Form Login Putih Bersih
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B4328),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Login to start renting your outdoor gear',
                      style: TextStyle(
                        fontSize: 14.5,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Input Email Address
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Email Address',
                        hintStyle: const TextStyle(color: Color(0xFF6E6A63)),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 16, right: 12),
                          child: Icon(
                            Icons.email,
                            color: Color(0xFF1E462B),
                            size: 22,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF3EBDC),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Email wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Input Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(color: Color(0xFF6E6A63)),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 16, right: 12),
                          child: Icon(
                            Icons.lock,
                            color: Color(0xFF1E462B),
                            size: 22,
                          ),
                        ),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFF5A5A5A),
                              size: 22,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF3EBDC),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Password wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 30),

                    // Tombol Login Hijau Tua Oval
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF234D2E),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: _handleLogin,
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Link ke Halaman Register ("Don't have an account? Sign Up")
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF37021),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Clipper untuk membuat lengkungan bergelombang halus di bawah gambar ilustrasi
class _WaveBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 25);

    path.quadraticBezierTo(
      size.width * 0.25,
      size.height - 45,
      size.width * 0.52,
      size.height - 22,
    );
    path.quadraticBezierTo(
      size.width * 0.80,
      size.height,
      size.width,
      size.height - 28,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
