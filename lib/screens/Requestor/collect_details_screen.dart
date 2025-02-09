import 'package:ciclou_projeto/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ColetaDetailsScreen extends StatelessWidget {
  final String documentId;
  final String requestorId; 

  const ColetaDetailsScreen({
    super.key,
    required this.documentId,
    required this.requestorId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.green1,
        centerTitle: true,
        title: const Text(
          'Detalhes da Coleta',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('requestor')
            .doc(requestorId)
            .get(),
        builder: (context, requestorSnapshot) {
          if (requestorSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!requestorSnapshot.hasData || !requestorSnapshot.data!.exists) {
            return const Center(
              child: Text(
                'Solicitante não encontrado.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final requestorData =
              requestorSnapshot.data!.data() as Map<String, dynamic>;
          final isNetUser = requestorData['IsNet'] ?? false;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('coletas')
                .doc(documentId)
                .get(),
            builder: (context, coletaSnapshot) {
              if (coletaSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!coletaSnapshot.hasData || !coletaSnapshot.data!.exists) {
                return const Center(
                  child: Text(
                    'Coleta não encontrada.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              }

              final data = coletaSnapshot.data!.data() as Map<String, dynamic>;

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildKeyValue(
                          'Estabelecimento',
                          data['tipoEstabelecimento'] ?? 'Não informado',
                        ),
                        const Divider(),
                        _buildKeyValue(
                          'Quantidade Estimada',
                          '${data['quantidadeOleo'] ?? '0'} Litros',
                        ),
                        _buildKeyValue(
                          'Quantidade Real',
                          '${data['quantidadeReal'] ?? '0'} Litros',
                        ),
                        _buildKeyValue(
                          'Preço por Litro',
                          'R\$${data['precoPorLitro'] ?? '0.00'}',
                        ),
                        const Divider(),
                        _buildKeyValue(
                          'Coletor',
                          data['collectorName'] ?? 'Não informado',
                        ),
                        const Divider(),
                        // Exibe Banco e Chave Pix apenas se não for IsNet
                        if (!isNetUser)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildKeyValue(
                                'Banco',
                                data['banco'] ?? 'Não informado',
                              ),
                              _buildKeyValue(
                                'Chave Pix',
                                data['chavePix'] ?? 'Não informado',
                              ),
                              const Divider(),
                            ],
                          ),
                        // Exibe o comprovante de pagamento apenas se não for IsNet
                        if (!isNetUser && data['comprovantePagamento'] != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Comprovante de Pagamento:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  data['comprovantePagamento'],
                                  fit: BoxFit.cover,
                                  height: 600,
                                  width: double.infinity,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Text(
                                        'Erro ao carregar imagem.',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    );
                                  },
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
          );
        },
      ),
    );
  }

  Widget _buildKeyValue(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '$key: ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}