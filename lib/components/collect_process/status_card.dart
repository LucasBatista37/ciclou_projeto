import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final Color textColor;

  const StatusCard({
    super.key,
    required this.message,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
