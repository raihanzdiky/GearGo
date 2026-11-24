import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class GearImageHelper {
  // Menyalin foto dari cache kamera/galeri ke folder permanen aplikasi
  static Future<String> saveImagePermanently(String tempPath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName =
        'geargo_${DateTime.now().millisecondsSinceEpoch}${p.extension(tempPath)}';
    final savedImage = await File(tempPath).copy('${appDir.path}/$fileName');
    return savedImage.path;
  }

  // [BARU] Dialog Preview Gambar Fullscreen dengan fitur Pinch-to-Zoom
  static void showZoomablePreview(
    BuildContext context, {
    required String? imagePath,
    required String title,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Area Gambar Interaktif (Bisa dicubit / zoom 0.8x - 4x)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: Colors.black,
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.72,
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Center(
                    child: GearImageDisplay(
                      imagePath: imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            // Header Judul & Tombol Tutup (X)
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.zoom_in, color: Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
            ),

            // Petunjuk Zoom di bagian bawah
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Cubit layar untuk memperbesar (Pinch to Zoom)',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GearImageDisplay extends StatelessWidget {
  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;

  const GearImageDisplay({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) {
      return Image.asset(
        'assets/images/logo_geargo.png',
        width: width,
        height: height,
        fit: BoxFit.contain,
      );
    }

    if (imagePath!.startsWith('assets/')) {
      return Image.asset(
        imagePath!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    }

    final file = File(imagePath!);
    if (file.existsSync()) {
      return Image.file(file, width: width, height: height, fit: fit);
    }

    return Image.asset(
      'assets/images/logo_geargo.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
