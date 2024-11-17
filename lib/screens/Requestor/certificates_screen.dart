import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class CertificatesScreen extends StatelessWidget {
  final String filePath;

  const CertificatesScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text(
          'Visualizar Certificados',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: PDFView(
        filePath: filePath,
      ),
    );
  }
}
