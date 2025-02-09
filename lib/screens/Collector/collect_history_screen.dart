import 'package:ciclou_projeto/models/user_model.dart';
import 'package:ciclou_projeto/screens/Collector/collector_dashboard.dart';
import 'package:ciclou_projeto/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CollectorHistoryScreen extends StatelessWidget {
  final String collectorId;
  final UserModel user;

  const CollectorHistoryScreen(
      {super.key, required this.collectorId, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.green1,
        centerTitle: true,
        title: const Text(
          'Histórico de Coletas',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CollectorDashboard(user: user),
              ),
            );
          },
        ),
      ),
      body: _buildHistoryList(context),
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('coletas')
          .where('collectorId', isEqualTo: collectorId)
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
          return const Center(
            child: Text(
              'Nenhuma coleta registrada.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final history = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: InkWell(
                  onTap: () {
                    // Optional: Add details page navigation or action
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                                color: Colors.green,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              decoration: BoxDecoration(
                                color: record['status'] == 'Finalizada'
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                record['status'] ?? 'Desconhecido',
                                style: TextStyle(
                                  color: record['status'] == 'Finalizada'
                                      ? Colors.green
                                      : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            const Icon(Icons.store,
                                color: Colors.grey, size: 20),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                'Estabelecimento: ${record['tipoEstabelecimento'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            const Icon(Icons.local_drink,
                                color: Colors.grey, size: 20),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                'Quantidade: ${record['quantidadeOleo'] ?? 'N/A'} Litros',
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            const Icon(Icons.person,
                                color: Colors.grey, size: 20),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                'Solicitante: ${record['requestorName'] ?? 'Não informado'}',
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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