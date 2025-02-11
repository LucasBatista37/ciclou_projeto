import 'package:ciclou_projeto/components/scaffold_mensager.dart';
import 'package:ciclou_projeto/screens/Requestor/collector_rating_screen.dart';
import 'package:ciclou_projeto/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ComprovanteVerificationScreen extends StatelessWidget {
  final String documentId;

  const ComprovanteVerificationScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('coletas')
          .doc(documentId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.green1,
              centerTitle: true,
              title: const Text(
                'Verificação de Comprovante',
                style: TextStyle(color: Colors.white),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final comprovanteUrl = data['comprovantePagamento'];

        if (comprovanteUrl == null || comprovanteUrl.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.green1,
              centerTitle: true,
              title: const Text(
                'Verificação de Comprovante',
                style: TextStyle(color: Colors.white),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            body: const Center(
              child: Text(
                'Nenhum comprovante enviado ou URL inválida.',
                style: TextStyle(fontSize: 18),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.green1,
            centerTitle: true,
            title: const Text(
              'Verificação de Comprovante',
              style: TextStyle(color: Colors.white),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.lightGreen.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300, width: 1),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info, color: Colors.green, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Verifique o comprovante enviado pelo coletor para validar a coleta.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      comprovanteUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text(
                            'Erro ao carregar a imagem do comprovante.',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('coletas')
                            .doc(documentId)
                            .update({
                          'comprovanteStatus': 'Inválido',
                          'comprovante': true,
                        });

                        ScaffoldMessengerHelper.showWarning(
                          // ignore: use_build_context_synchronously
                          context: context,
                          message: 'Comprovante marcado como inválido.',
                        );

                        final querySnapshot = await FirebaseFirestore.instance
                            .collection('coletas')
                            .doc(documentId)
                            .collection('propostas')
                            .where('status', isEqualTo: 'Aceita')
                            .limit(1)
                            .get();

                        if (querySnapshot.docs.isNotEmpty) {}

                        Navigator.pushReplacement(
                          // ignore: use_build_context_synchronously
                          context,
                          MaterialPageRoute(
                            builder: (_) => CollectorProposalRatingScreen(
                              coletaId: documentId,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 24.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text(
                        'Inválido',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('coletas')
                            .doc(documentId)
                            .update({
                          'comprovanteStatus': 'Válido',
                          'comprovante': true,
                        });

                        ScaffoldMessengerHelper.showSuccess(
                          // ignore: use_build_context_synchronously
                          context: context,
                          message: 'Comprovante marcado como válido!',
                        );

                        final querySnapshot = await FirebaseFirestore.instance
                            .collection('coletas')
                            .doc(documentId)
                            .collection('propostas')
                            .where('status', isEqualTo: 'Aceita')
                            .limit(1)
                            .get();

                        if (querySnapshot.docs.isNotEmpty) {}

                        Navigator.pushReplacement(
                          // ignore: use_build_context_synchronously
                          context,
                          MaterialPageRoute(
                            builder: (_) => CollectorProposalRatingScreen(
                              coletaId: documentId,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 24.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text(
                        'Válido',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
