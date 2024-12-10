import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CollectorHistoryScreen extends StatefulWidget {
  final String collectorId;

  const CollectorHistoryScreen({super.key, required this.collectorId});

  @override
  _CollectorHistoryScreenState createState() => _CollectorHistoryScreenState();
}

class _CollectorHistoryScreenState extends State<CollectorHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text(
          'Histórico de Coletas',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _buildHistoryList(),
    );
  }

  Widget _buildHistoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('coletas')
          .where('collectorId', isEqualTo: widget.collectorId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Erro ao carregar dados: ${snapshot.error}');
          return const Center(child: Text('Erro ao carregar o histórico.'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print(
              'Nenhuma coleta encontrada para o collectorId: ${widget.collectorId}');
          return const Center(child: Text('Nenhuma coleta registrada.'));
        }

        final historico = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: historico.length,
            itemBuilder: (context, index) {
              final coleta = historico[index].data() as Map<String, dynamic>;
              final createdAt = coleta['createdAt'] is Timestamp
                  ? (coleta['createdAt'] as Timestamp).toDate()
                  : null;
              final formattedDate = createdAt != null
                  ? "${createdAt.day.toString().padLeft(2, '0')}/"
                      "${createdAt.month.toString().padLeft(2, '0')}/"
                      "${createdAt.year}"
                  : 'Data não disponível';
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title:
                      Text('Tipo: ${coleta['tipoEstabelecimento'] ?? 'N/A'}'),
                  subtitle: Text(
                      'Data: $formattedDate\nQuantidade: ${coleta['quantidadeOleo'] ?? 'N/A'} Litros'),
                  trailing: _buildStatusTag(coleta['status'] ?? 'Desconhecido'),
                  onTap: () {},
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatusTag(String status) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'Concluída':
      case 'Finalizada':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Em andamento':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      case 'Cancelada':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(statusIcon, color: statusColor, size: 18.0),
        const SizedBox(width: 4.0),
        Text(
          status,
          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
