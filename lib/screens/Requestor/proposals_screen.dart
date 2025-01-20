import 'dart:io';
import 'package:ciclou_projeto/components/generate_payment_screen.dart';
import 'package:ciclou_projeto/components/scaffold_mensager.dart';
import 'package:ciclou_projeto/models/user_model.dart';
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
    final tempoMaximoColeta = proposal['tempoMaximoColeta'] ?? 'N/A';
    final valorTotalPago = proposal['valorTotalPago'] ?? 'N/A';

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
                        'Tempo Máximo para Realizar Coleta: $tempoMaximoColeta horas',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Valor Total a ser Pago: R\$ $valorTotalPago',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
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
                      if (!isEmAndamento)
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(child: CircularProgressIndicator());
        },
      );

      final coletaData = await _fetchCollectionData(documentId);
      if (coletaData.isEmpty || !coletaData.containsKey('quantidadeOleo')) {
        throw Exception('Quantidade de óleo não especificada na coleta.');
      }
      final quantityOleo = coletaData['quantidadeOleo'];

      final proposalData = await _fetchProposalData(documentId, proposalId);
      if (proposalData.isEmpty || !proposalData.containsKey('collectorId')) {
        throw Exception('Erro: coletor não encontrado.');
      }

      final collectorId = proposalData['collectorId'];
      final collectorName = proposalData['collectorName'];
      final precoPorLitro = proposalData['precoPorLitro'];

      final amount = _calculateAmount(double.parse(quantityOleo.toString()));

      await _updateProposalStatus(documentId, proposalId);

      await _updateCollectionStatus(
          documentId, collectorId, collectorName, precoPorLitro);

      _sendNotification(
        collectorId,
        'Proposta Aceita!',
        'Sua proposta para $solicitationTitle foi aceita. Prepare-se para a coleta!',
        documentId,
      );

      await _generateQRCodes(
          coletaData, proposalData, documentId, proposalId, amount);

      ScaffoldMessengerHelper.showSuccess(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Proposta aceita com sucesso! Coleta em andamento.',
      );
    } catch (error) {
      ScaffoldMessengerHelper.showError(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Erro ao aceitar proposta.',
      );
    } finally {
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
    }
  }

  Future<Map<String, dynamic>> _fetchCollectionData(String documentId) async {
    final coletaDoc = await FirebaseFirestore.instance
        .collection('coletas')
        .doc(documentId)
        .get();

    return coletaDoc.data() ?? {};
  }

  Future<Map<String, dynamic>> _fetchProposalData(
      String documentId, String proposalId) async {
    final proposalDoc = await FirebaseFirestore.instance
        .collection('coletas')
        .doc(documentId)
        .collection('propostas')
        .doc(proposalId)
        .get();

    return proposalDoc.data() ?? {};
  }

  Future<void> _updateProposalStatus(
      String documentId, String proposalId) async {
    await FirebaseFirestore.instance
        .collection('coletas')
        .doc(documentId)
        .collection('propostas')
        .doc(proposalId)
        .update({'status': 'Aceita'});
  }

  Future<void> _updateCollectionStatus(String documentId, String collectorId,
      String collectorName, String precoPorLitro) async {
    await FirebaseFirestore.instance
        .collection('coletas')
        .doc(documentId)
        .update({
      'status': 'Em andamento',
      'collectorId': collectorId,
      'collectorName': collectorName,
      'precoPorLitro': precoPorLitro,
    });
  }

  Future<void> _generateQRCodes(
      Map<String, dynamic> coletaData,
      Map<String, dynamic> proposalData,
      String documentId,
      String proposalId,
      double amount) async {
    final principalQrCodeData = await generateFixedPixPayment(
      amount: amount.toString(),
      user: user,
      documentId: documentId,
      proposalId: proposalId,
    );

    if (principalQrCodeData != null) {
      await FirebaseFirestore.instance
          .collection('coletas')
          .doc(documentId)
          .collection('propostas')
          .doc(proposalId)
          .update({
        'qrCode': principalQrCodeData['qrCode'],
        'qrCodeBase64': principalQrCodeData['qrCodeBase64'],
        'paymentId': principalQrCodeData['paymentId'],
      });
    } else {
      // ignore: avoid_print
      print('Erro: Falha ao gerar QR Code principal.');
    }

    if (coletaData['IsNetCollection'] == true) {
      final valorTotalPago = proposalData['valorTotalPago']?.toString();
      if (valorTotalPago != null) {
        final solicitanteQrCodeData = await generateFixedPixPayment(
          amount: valorTotalPago,
          user: user,
          documentId: documentId,
          proposalId: proposalId,
        );

        if (solicitanteQrCodeData != null) {
          await FirebaseFirestore.instance
              .collection('coletas')
              .doc(documentId)
              .collection('propostas')
              .doc(proposalId)
              .update({
            'qrCodeSolicitante': solicitanteQrCodeData['qrCode'],
            'qrCodeTextSolicitante': solicitanteQrCodeData['qrCodeBase64'],
            'paymentIdSolicitante': solicitanteQrCodeData['paymentId'],
            'statusSolicitante': 'Pendente',
          });
        } else {
          // ignore: avoid_print
          print('Erro: Falha ao gerar QR Code para o solicitante.');
        }
      }
    }
  }

  double _calculateAmount(double liters) {
    if (liters > 100) return 20.0;
    if (liters >= 20 && liters <= 30) return 7.5;
    if (liters > 30 && liters <= 45) return 10.0;
    if (liters > 45 && liters <= 60) return 12.0;
    if (liters > 60 && liters <= 75) return 14.0;
    if (liters > 75 && liters <= 100) return 16.0;
    throw Exception('Quantidade de litros fora do intervalo permitido.');
  }

  Future<void> _rejectProposal(BuildContext context, String proposalId) async {
    try {
      final proposalDoc = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(documentId)
          .collection('propostas')
          .doc(proposalId)
          .get();

      final proposalData = proposalDoc.data();

      if (proposalData == null || proposalData['collectorId'] == null) {
        ScaffoldMessengerHelper.showError(
          // ignore: use_build_context_synchronously
          context: context,
          message: 'Erro: coletor não encontrado',
        );
        return;
      }

      final collectorId = proposalData['collectorId'];

      await FirebaseFirestore.instance
          .collection('coletas')
          .doc(documentId)
          .collection('propostas')
          .doc(proposalId)
          .update({'status': 'Rejeitada'});

      _sendNotification(
        collectorId,
        'Proposta Rejeitada',
        'Sua proposta para a coleta foi rejeitada.',
        documentId,
      );

      ScaffoldMessengerHelper.showWarning(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Proposta Rejeitada',
      );
    } catch (error) {
      ScaffoldMessengerHelper.showError(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Erro ao rejeitar proposta',
      );
    }
  }

  void _sendNotification(
      String collectorId, String title, String message, String coletaId) {
    FirebaseFirestore.instance.collection('notifications').add({
      'title': title,
      'message': message,
      'collectorId': collectorId,
      'coletaId': coletaId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }
}