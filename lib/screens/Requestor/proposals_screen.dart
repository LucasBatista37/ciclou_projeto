import 'dart:convert';
import 'dart:io';
import 'package:ciclou_projeto/components/generate_payment_screen.dart';
import 'package:http/http.dart' as http;
import 'package:ciclou_projeto/models/user_model.dart';
import 'package:ciclou_projeto/screens/Requestor/requestor_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProposalsScreen extends StatelessWidget {
  final String solicitationTitle;
  final String documentId;
  final UserModel user;

  const ProposalsScreen({
    super.key,
    required this.solicitationTitle,
    required this.documentId,
    required this.user,
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

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('coletas')
          .doc(documentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final coletaData = snapshot.data!.data() as Map<String, dynamic>?;

        final isEmAndamento = coletaData?['status'] == 'Em andamento';

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
                          style: const TextStyle(
                              fontSize: 20, color: Colors.white),
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
                        'Preço por Litro: R\$ ${proposal['precoPorLitro'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Status: ${proposal['status'] ?? 'Indefinido'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: proposal['status'] == 'Aceita'
                              ? Colors.green
                              : proposal['status'] == 'Rejeitada'
                                  ? Colors.red
                                  : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      if (!isEmAndamento) // Se não estiver em andamento, mostra os botões
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
                              onPressed: () async {
                                await _acceptProposal(
                                    context, proposalId, proposal);
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
                        )
                      else
                        const Text(
                          'Propostas desativadas (coleta em andamento)',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  Future<void> _acceptProposal(BuildContext context, String proposalId,
      Map<String, dynamic> proposal) async {
    try {
      // Buscar dados do documento de coleta
      final coletaDoc = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(documentId)
          .get();

      final coletaData = coletaDoc.data();

      // Validar se os dados de coleta existem
      if (coletaData == null || coletaData['quantidadeOleo'] == null) {
        throw Exception('Quantidade de óleo não especificada na coleta.');
      }

      final quantityOleo = coletaData['quantidadeOleo'];

      // Buscar dados da proposta
      final proposalDoc = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(documentId)
          .collection('propostas')
          .doc(proposalId)
          .get();

      final proposalData = proposalDoc.data();

      // Validar se os dados da proposta existem
      if (proposalData == null || proposalData['collectorId'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: coletor não encontrado.')),
        );
        return;
      }

      // Extrair informações da proposta
      final collectorId = proposalData['collectorId'];
      final collectorName = proposalData['collectorName'];
      final precoPorLitro = proposalData['precoPorLitro'];

      // Calcular o valor baseado na quantidade de óleo
      final amount = _calculateAmount(double.parse(quantityOleo.toString()));

      // Atualizar status da proposta para "Aceita"
      await FirebaseFirestore.instance
          .collection('coletas')
          .doc(documentId)
          .collection('propostas')
          .doc(proposalId)
          .update({'status': 'Aceita'});

      // Atualizar status da coleta para "Em andamento"
      await FirebaseFirestore.instance
          .collection('coletas')
          .doc(documentId)
          .update({
        'status': 'Em andamento',
        'collectorId': collectorId,
        'collectorName': collectorName,
        'precoPorLitro': precoPorLitro,
      });

      // Enviar notificação ao coletor
      _sendNotification(
        collectorId,
        'Proposta Aceita!',
        'Sua proposta para $solicitationTitle foi aceita. Prepare-se para a coleta!',
      );

      // Gerar pagamento PIX
      await generateFixedPixPayment(
        amount: amount.toString(),
        user: user,
        documentId: documentId,
        proposalId: proposalId,
      );

      // Exibir mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proposta aceita com sucesso! Coleta em andamento.'),
        ),
      );

      // Navegar para o painel do solicitante
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => RequestorDashboard(user: user)),
        (Route<dynamic> route) => false,
      );
    } catch (error) {
      // Exibir mensagem de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aceitar a proposta: $error')),
      );
    }
  }

  double _calculateAmount(double liters) {
    if (liters >= 20 && liters <= 30) return 7.5;
    if (liters > 30 && liters <= 45) return 10.0;
    if (liters > 45 && liters <= 60) return 12.0;
    if (liters > 60 && liters <= 75) return 14.0;
    if (liters > 75 && liters <= 100) return 16.0;
    throw Exception('Quantidade de litros fora do intervalo permitido.');
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
      'isRead': false,
    });
  }
}
