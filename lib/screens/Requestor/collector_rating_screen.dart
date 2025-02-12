import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:ciclou_projeto/components/scaffold_mensager.dart';
import 'package:ciclou_projeto/utils/colors.dart';

class CollectorProposalRatingScreen extends StatefulWidget {
  final String coletaId;

  const CollectorProposalRatingScreen({
    super.key,
    required this.coletaId,
  });

  @override
  State<CollectorProposalRatingScreen> createState() =>
      _CollectorProposalRatingScreenState();
}

class _CollectorProposalRatingScreenState
    extends State<CollectorProposalRatingScreen> {
  bool _isLoading = false;
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();

  Future<void> _sendRating({
    required Map<String, dynamic> collectorData,
    required String collectorId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Você não está autenticado.',
      );
      return;
    }

    if (_rating < 1) {
      ScaffoldMessengerHelper.showWarning(
        context: context,
        message: 'Selecione ao menos 1 estrela para avaliar.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('ratings').add({
        'collectorId': collectorId,
        'businessName': collectorData['businessName'] ?? '',
        'cnpj': collectorData['cnpj'] ?? '',
        'phone': collectorData['phone'] ?? '',
        'address': collectorData['address'] ?? '',
        'responsible': collectorData['responsible'] ?? '',
        'userType': collectorData['userType'] ?? 'Coletor',
        'rating': _rating,
        'feedback': _commentController.text.trim(),
        'ratedBy': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('coletas')
          .doc(widget.coletaId)
          .update({'rating': true});

      ScaffoldMessengerHelper.showSuccess(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Avaliação enviada com sucesso!',
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Erro ao enviar avaliação. Tente novamente.',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        return IconButton(
          onPressed: () => setState(() => _rating = starNumber),
          icon: Icon(
            Icons.star,
            size: 40,
            color: (starNumber <= _rating) ? Colors.orange : Colors.grey,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avaliar Coletor',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.green1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('coletas')
              .doc(widget.coletaId)
              .collection('propostas')
              .where('status', isEqualTo: 'Aceita')
              .limit(1)
              .get(),
          builder: (context, proposalSnap) {
            if (proposalSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (proposalSnap.hasError) {
              return const Center(
                child: Text('Erro ao carregar a(s) proposta(s).'),
              );
            }
            final docs = proposalSnap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(
                child: Text('Nenhuma proposta aceita encontrada.'),
              );
            }
            final proposalData = docs.first.data() as Map<String, dynamic>;
            final collectorId = proposalData['collectorId'] as String?;
            final collectorName = proposalData['collectorName'] ?? 'Coletor';

            if (collectorId == null) {
              return Center(
                child: Text('collectorId não encontrado na proposta.'),
              );
            }

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('collector')
                  .doc(collectorId)
                  .get(),
              builder: (context, collectorSnap) {
                if (collectorSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (collectorSnap.hasError) {
                  return const Center(
                    child: Text('Erro ao carregar dados do coletor.'),
                  );
                }
                if (!collectorSnap.hasData || !collectorSnap.data!.exists) {
                  return Center(
                    child: Text('Coletor $collectorId não encontrado.'),
                  );
                }

                final collectorData =
                    collectorSnap.data!.data() as Map<String, dynamic>;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Avaliar: $collectorName',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      _buildStarRating(),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _commentController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Comentário (opcional)',
                          hintText: 'Deixe uma observação ou crítica...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide:
                                const BorderSide(color: Colors.green, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () => _sendRating(
                                    collectorData: collectorData,
                                    collectorId: collectorId,
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'Enviar Avaliação',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
