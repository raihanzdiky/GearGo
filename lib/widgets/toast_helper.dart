import 'package:flutter/material.dart';

class ToastHelper {
  static void show(
    BuildContext context,
    String message, {
    Color backgroundColor = const Color(0xFF1B4332),
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    // Hapus SnackBar lama agar tidak menumpuk
    messenger.clearSnackBars();

    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: action,
      ),
    );

    // Paksa tutup setelah durasi habis (mengatasi bug Accessibility Android)
    Future.delayed(duration, () {
      try {
        controller.close();
      } catch (_) {}
    });
  }

  static void clear(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}