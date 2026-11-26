import 'package:flutter/material.dart';

import 'database/database_helper.dart';
import 'data/cart_manager.dart';
import 'models/user_model.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cek apakah ada sesi login yang tersimpan sebelumnya
  final UserModel? savedUser = await DatabaseHelper.instance
      .getActiveSessionUser();
  if (savedUser != null) {
    DatabaseHelper.currentUser = savedUser;
    if (savedUser.role == 'customer') {
      await CartManager.loadForCurrentUser();
    }
  }

  runApp(const GearGoApp());
}

class GearGoApp extends StatelessWidget {
  const GearGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GearGo - Sewa Outdoor Pintar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B4332),
          primary: const Color(0xFF1B4332),
          secondary: const Color(0xFFF37021),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4EFE6),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
