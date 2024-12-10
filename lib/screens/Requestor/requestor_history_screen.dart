  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:flutter/material.dart';

  class RequestorHistoryScreen extends StatelessWidget {
    final String userId;

    const RequestorHistoryScreen({super.key, required this.userId});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Histórico de Coletas',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _buildHistoryList(),
      );
    }

    Widget _buildHistoryList() {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('coletas')
            .where('userId', isEqualTo: userId)
            .where('status', whereIn: ['Finalizada', 'Em andamento'])
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar o histórico.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhuma coleta registrada.'));
          }

          final history = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final record = history[index].data() as Map<String, dynamic>;
                final createdAt = record['createdAt'] is Timestamp
                    ? (record['createdAt'] as Timestamp).toDate()
                    : null;
                final formattedDate = createdAt != null
                    ? "${createdAt.day.toString().padLeft(2, '0')}/"
                        "${createdAt.month.toString().padLeft(2, '0')}/"
                        "${createdAt.year}"
                    : 'Data não disponível';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data: $formattedDate',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                            'Tipo de Estabelecimento: ${record['tipoEstabelecimento'] ?? 'N/A'}'),
                        Text(
                            'Coletor: ${record['collectorName'] ?? 'Não informado'}'),
                        Text(
                            'Quantidade: ${record['quantidadeOleo'] ?? 'N/A'} Litros'),
                        Text(
                          'Status: ${record['status'] ?? 'Desconhecido'}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    }
  }
