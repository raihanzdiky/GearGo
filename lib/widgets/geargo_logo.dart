import 'package:flutter/material.dart';

class GearGoLogo extends StatelessWidget {
  final bool isLight;
  final double iconSize;
  final double fontSize;

  const GearGoLogo({
    super.key,
    this.isLight = false,
    this.iconSize = 80,
    this.fontSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo_geargo.png',
          width: iconSize * 1.8, // Menyesuaikan lebar logo agar proporsional
          height: iconSize * 1.4,
          fit: BoxFit.contain,
          // Jika logo hanya 1 warna gelap, baris di bawah membuat logo otomatis putih di Splash Screen:
          color: isLight ? Colors.white : null,
        ),
      ],
    );
  }
}
