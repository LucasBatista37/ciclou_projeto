import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProposalsScreen extends StatelessWidget {
  final String solicitationTitle;
  final String documentId;

  const ProposalsScreen({
    super.key,
    required this.solicitationTitle,
    required this.documentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Propostas para $solicitationTitle',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('coletas')
            .doc(documentId)
            .collection('propostas')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar propostas.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final proposals = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: proposals.length,
              itemBuilder: (context, index) {
                final data = proposals[index].data() as Map<String, dynamic>;
                return _buildProposalCard(context, data, proposals[index].id);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 100,
            color: Colors.grey,
          ),
          SizedBox(height: 16.0),
          Text(
            'Nenhuma proposta encontrada.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProposalCard(
      BuildContext context, Map<String, dynamic> proposal, String proposalId) {
    final photoUrl = proposal['photoUrl'];
    final displayInitial = proposal['collectorName']?[0]?.toUpperCase() ?? 'A';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: _getImageProvider(photoUrl),
              backgroundColor: Colors.grey,
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? Text(
                      displayInitial,
                      style: const TextStyle(fontSize: 20, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    proposal['collectorName'] ?? 'Desconhecido',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Preço por Litro: ${proposal['precoPorLitro'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Status: ${proposal['status'] ?? 'Indefinido'}',
                    style: TextStyle(
                      fontSize: 16,
                      color: proposal['status'] == 'Aceito'
                          ? Colors.green
                          : proposal['status'] == 'Rejeitado'
                              ? Colors.red
                              : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _rejectProposal(context, proposalId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text(
                          'Rejeitar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      ElevatedButton(
                        onPressed: () {
                          _acceptProposal(context, proposalId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text(
                          'Aceitar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _getImageProvider(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return null;
    }
    if (photoUrl.startsWith('http')) {
      return NetworkImage(photoUrl);
    }
    if (photoUrl.startsWith('/')) {
      return FileImage(File(photoUrl));
    }
    return null;
  }

  void _acceptProposal(BuildContext context, String proposalId) async {
    try {
      final proposalDoc = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(documentId)
          .collection('propostas')
          .doc(proposalId)
          .get();

      final proposalData = proposalDoc.data();

      if (proposalData == null || proposalData['collectorId'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: coletor não encontrado.')),
        );
        return;
      }

      final collectorId = proposalData['collectorId'];
      final collectorName = proposalData['collectorName'];

      await FirebaseFirestore.instance
          .collection('coletas')
          .doc(documentId)
          .collection('propostas')
          .doc(proposalId)
          .update({'status': 'Aceita'});

      await FirebaseFirestore.instance
          .collection('coletas')
          .doc(documentId)
          .update({
        'status': 'Em andamento',
        'collectorId': collectorId,
        'collectorName': collectorName,
      });

      _sendNotification(
        collectorId,
        'Proposta Aceita!',
        'Sua proposta para $solicitationTitle foi aceita. Prepare-se para a coleta!',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Proposta aceita com sucesso! Coleta em andamento.')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aceitar a proposta: $error')),
      );
    }
  }

  void _rejectProposal(BuildContext context, String proposalId) {
    FirebaseFirestore.instance
        .collection('coletas')
        .doc(documentId)
        .collection('propostas')
        .doc(proposalId)
        .get()
        .then((proposalDoc) {
      final proposalData = proposalDoc.data();
      if (proposalData != null && proposalData['collectorId'] != null) {
        final collectorId = proposalData['collectorId'];

        FirebaseFirestore.instance
            .collection('coletas')
            .doc(documentId)
            .collection('propostas')
            .doc(proposalId)
            .update({'status': 'Rejeitada '}).then((_) {
          _sendNotification(
            collectorId,
            'Proposta Rejeitada',
            'Sua proposta para $solicitationTitle foi rejeitada.',
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Proposta rejeitada com sucesso!')),
          );
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao rejeitar proposta: $error')),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: coletor não encontrado.')),
        );
      }
    });
  }

  void _sendNotification(String collectorId, String title, String message) {
    FirebaseFirestore.instance.collection('notifications').add({
      'title': title,
      'message': message,
      'collectorId': collectorId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}