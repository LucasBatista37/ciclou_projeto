import 'package:ciclou_projeto/screens/Collector/collect_process.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CollectsScreen extends StatefulWidget {
  final String collectorId;

  const CollectsScreen({super.key, required this.collectorId});

  @override
  _CollectsScreenState createState() => _CollectsScreenState();
}

class _CollectsScreenState extends State<CollectsScreen> {
  bool _carregando = true;
  List<DocumentSnapshot> _coletas = [];

  @override
  void initState() {
    super.initState();
    _carregarColetasEmAndamento();
  }

  Future<void> _carregarColetasEmAndamento() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('coletas')
          .where('status', whereIn: ['Em andamento', 'Aprovado'])
          .where('collectorId', isEqualTo: widget.collectorId)
          .get();

      setState(() {
        _coletas = querySnapshot.docs;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _carregando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar coletas: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text(
          'Coletas em Andamento',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.green,
                strokeWidth: 5.0,
              ),
            )
          : _coletas.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma coleta em andamento.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _coletas.length,
                  itemBuilder: (context, index) {
                    final coleta = _coletas[index];
                    final coletaData = coleta.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.store, color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Estabelecimento: ${coletaData['tipoEstabelecimento'] ?? 'N/A'}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.oil_barrel, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                  'Quantidade: ${coletaData['quantidadeOleo'] ?? 'N/A'} Litros',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 10.0),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CollectProcess(
                                        coletaAtual: coleta,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.open_in_new,
                                    color: Colors.white),
                                label: const Text(
                                  'Ver Detalhes',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}