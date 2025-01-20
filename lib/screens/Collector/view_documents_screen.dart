import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class DocumentViewerScreen extends StatelessWidget {
  final String documentUrl;
  final String documentType;

  const DocumentViewerScreen({
    super.key,
    required this.documentUrl,
    required this.documentType,
  });

  @override
  Widget build(BuildContext context) {
    final isPdf = documentUrl.toLowerCase().endsWith('.pdf');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          documentType,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isPdf
          ? PDFView(
              filePath: documentUrl,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageSnap: true,
              fitPolicy: FitPolicy.BOTH,
              onRender: (_pages) {
                debugPrint('PDF Rendered: $_pages pages');
              },
              onError: (error) {
                debugPrint('PDF Error: $error');
              },
            )
          : Center(
              child: Image.network(
                documentUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    'Erro ao carregar imagem.',
                    style: TextStyle(color: Colors.red),
                  );
                },
              ),
            ),
    );
  }
}
