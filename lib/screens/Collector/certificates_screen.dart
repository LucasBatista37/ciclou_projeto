import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});

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
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('certificados').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Erro ao carregar certificados.'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Nenhum certificado encontrado.'),
            );
          }

          final certificados = snapshot.data!.docs;

          return ListView.builder(
            itemCount: certificados.length,
            itemBuilder: (context, index) {
              final certificado = certificados[index];
              final filePath = certificado['filePath'];
              final coletaId = certificado['coletaId'];
              final createdAt = certificado['createdAt'] != null
                  ? (certificado['createdAt'] as Timestamp).toDate()
                  : null;

              return ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text('Certificado - Coleta $coletaId'),
                subtitle: createdAt != null
                    ? Text('Criado em: ${createdAt.toLocal()}')
                    : const Text('Data não disponível'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PDFViewScreen(filePath: filePath),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class PDFViewScreen extends StatelessWidget {
  final String filePath;

  const PDFViewScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text(
          'Visualizar PDF',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: PDFView(
        filePath: filePath,
      ),
    );
  }
}