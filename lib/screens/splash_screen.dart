import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import 'main_navigation.dart';
import 'owner_dashboard_screen.dart';
import 'login_screen.dart';
import '../widgets/geargo_logo.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Gradasi Hijau Hutan Gelap
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0E261B),
                  Color(0xFF1B4332),
                  Color(0xFF23533E),
                ],
              ),
            ),
          ),

          // 2. Aksen Garis Kontur Topografi Halus
          Positioned.fill(
            child: CustomPaint(painter: _TopographyBackgroundPainter()),
          ),

          // 3. Konten Utama
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge Kecil di Atas
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.explore,
                            color: Color(0xFFF37021),
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'SMART OUTDOOR RENTAL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bagian Tengah: Logo dengan Cahaya Radial Halus (Tanpa Teks Dobel)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        width: 280,
                        height: 280,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // RadialGradient membuat cahaya memudar halus tanpa garis tepi tajam
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF52B788).withOpacity(0.18),
                              const Color(0xFF1B4332).withOpacity(0.0),
                            ],
                            stops: const [0.1, 1.0],
                          ),
                        ),
                        child: const GearGoLogo(
                          isLight: true,
                          iconSize: 155,
                          fontSize: 42,
                        ),
                      ),
                    ),
                  ),

                  // Bagian Bawah: Kartu Glassmorphism + Tombol Aksi Modern
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.09),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Siap Menjelajah Alam?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Sewa perlengkapan gunung berkualitas, cek kapasitas beban, dan mulai petualanganmu.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13.5,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Tombol Utama Oranye Modern
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF37021),
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shadowColor: const Color(0xFFF37021)
                                      .withOpacity(0.45),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () {
                                  final user = DatabaseHelper.currentUser;
                                  Widget targetScreen;

                                  if (user == null) {
                                    targetScreen = const LoginScreen();
                                  } else if (user.role == 'owner') {
                                    targetScreen = const OwnerDashboardScreen();
                                  } else {
                                    targetScreen = const MainNavigation();
                                  }

                                  Navigator.pushReplacement(
                                    context,
                                    PageRouteBuilder(
                                      transitionDuration: const Duration(
                                        milliseconds: 450,
                                      ),
                                      pageBuilder: (_, __, ___) => targetScreen,
                                      transitionsBuilder:
                                          (_, animation, __, child) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            );
                                          },
                                    ),
                                  );
                                },
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'Mulai Petualangan',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopographyBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (int i = 1; i <= 5; i++) {
      final path = Path()
        ..moveTo(size.width * 0.35, 0)
        ..quadraticBezierTo(
          size.width * (0.45 + i * 0.06),
          size.height * (0.12 + i * 0.05),
          size.width,
          size.height * (0.18 + i * 0.06),
        );
      canvas.drawPath(path, paint);
    }

    for (int i = 1; i <= 5; i++) {
      final path = Path()
        ..moveTo(0, size.height * (0.55 + i * 0.05))
        ..quadraticBezierTo(
          size.width * (0.25 + i * 0.05),
          size.height * (0.60 + i * 0.04),
          size.width * 0.55,
          size.height,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
