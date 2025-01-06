import 'package:flutter/material.dart';

class ScaffoldMessengerHelper {
  static void showMessage({
    required BuildContext context,
    required String message,
    Color backgroundColor = Colors.black,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }

  static void showSuccess({
    required BuildContext context,
    required String message,
  }) {
    showMessage(
      context: context,
      message: message,
      backgroundColor: Colors.green,
    );
  }

  static void showError({
    required BuildContext context,
    required String message,
  }) {
    showMessage(
      context: context,
      message: message,
      backgroundColor: Colors.red,
    );
  }

  static void showWarning({
    required BuildContext context,
    required String message,
  }) {
    showMessage(
      context: context,
      message: message,
      backgroundColor: Colors.orange,
    );
  }
}
