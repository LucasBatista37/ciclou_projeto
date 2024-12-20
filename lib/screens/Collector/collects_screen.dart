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
          .where('status', isEqualTo: 'Em andamento')
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
          ? const Center(child: CircularProgressIndicator())
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
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tipo de Estabelecimento: ${coleta['tipoEstabelecimento'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Quantidade Estimada: ${coleta['quantidadeOleo'] ?? 'N/A'} Litros',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
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
                                child: const Text(
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
