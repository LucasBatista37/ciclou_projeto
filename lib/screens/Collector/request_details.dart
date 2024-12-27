import 'package:ciclou_projeto/models/user_model.dart';
import 'package:ciclou_projeto/screens/Collector/send_proposal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RequestDetails extends StatelessWidget {
  final String tipoEstabelecimento;
  final String quantidadeOleo;
  final String prazo;
  final String endereco;
  final String observacoes;
  final String documentId;
  final String funcionamentoDias;
  final String funcionamentoHorario;
  final UserModel user;

  const RequestDetails({
    super.key,
    required this.tipoEstabelecimento,
    required this.quantidadeOleo,
    required this.prazo,
    required this.endereco,
    required this.observacoes,
    required this.documentId,
    required this.funcionamentoDias,
    required this.funcionamentoHorario,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime prazoDateTime = DateTime.parse(prazo);
    final String prazoFormatado =
        DateFormat('dd/MM/yyyy HH:mm').format(prazoDateTime);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text(
          'Detalhes da Solicitação',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem('Tipo de Estabelecimento', tipoEstabelecimento),
            const Divider(height: 24.0, thickness: 1.0),
            _buildDetailItem('Quantidade de Óleo Estimada', quantidadeOleo),
            const Divider(height: 24.0, thickness: 1.0),
            _buildDetailItem('Prazo para Propostas', prazoFormatado),
            const Divider(height: 24.0, thickness: 1.0),
            _buildDetailItem('Endereço', endereco),
            const Divider(height: 24.0, thickness: 1.0),
            _buildDetailItem(
              'Observações Adicionais',
              observacoes.isNotEmpty ? observacoes : 'Nenhuma observação',
            ),
            const Divider(height: 24.0, thickness: 1.0),
            _buildDetailItem('Dias de Funcionamento', funcionamentoDias),
            const Divider(height: 24.0, thickness: 1.0),
            _buildDetailItem('Horário de Funcionamento', funcionamentoHorario),
            const SizedBox(height: 24.0),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SendProposal(
                        documentId: documentId,
                        user: user,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Enviar Proposta',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        Text(
          value,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ],
    );
  }
}