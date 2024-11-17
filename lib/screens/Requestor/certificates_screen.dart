import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class CertificatesScreen extends StatelessWidget {
  final String filePath;

  const CertificatesScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visualizar Certificado'),
        backgroundColor: Colors.green,
      ),
      body: PDFView(
        filePath: filePath,
      ),
    );
  }
}
