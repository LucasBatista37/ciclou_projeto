import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompartilharColetaScreen extends StatefulWidget {
  final String coletaId;

  const CompartilharColetaScreen({Key? key, required this.coletaId})
      : super(key: key);

  @override
  State<CompartilharColetaScreen> createState() =>
      _CompartilharColetaScreenState();
}

class _CompartilharColetaScreenState extends State<CompartilharColetaScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _coletores = [];
  List<DocumentSnapshot> _filteredColetores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchColetores();
  }

  Future<void> _fetchColetores() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('collector')
          .where('IsNet', isEqualTo: true)
          .get();

      setState(() {
        _coletores = snapshot.docs;
        _filteredColetores = snapshot.docs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar coletores: $e')),
      );
    }
  }

  void _filterColetores(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredColetores = _coletores;
      } else {
        _filteredColetores = _coletores.where((coletor) {
          String nome = coletor['responsible'] ?? '';
          return nome.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text(
          'Compartilhar Coleta',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Column(
                    children: const [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.green,
                        size: 64,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'ATENÇÃO!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Você está compartilhando sua coleta. Escolha cautelosamente o coletor responsável.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Pesquisar coletor',
                      labelStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.green),
                    ),
                    onChanged: (value) => _filterColetores(value),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _filteredColetores.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhum coletor encontrado.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredColetores.length,
                            itemBuilder: (context, index) {
                              final coletor = _filteredColetores[index];
                              return Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green[100],
                                    child: const Icon(Icons.person,
                                        color: Colors.green),
                                  ),
                                  title: Text(
                                    coletor['responsible'] ?? 'Sem Nome',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    coletor['email'] ?? 'Sem Email',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.share,
                                        color: Colors.green),
                                    onPressed: () =>
                                        _confirmarCompartilhamento(coletor),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  void _confirmarCompartilhamento(DocumentSnapshot coletor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Confirmar Compartilhamento'),
          content: Text(
            'Deseja compartilhar sua coleta com o coletor ${coletor['responsible']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                FirebaseFirestore.instance.collection('compartilhamentos').add({
                  'coletorId': coletor.id,
                  'coletorName': coletor['responsible'],
                  'timestamp': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Coleta compartilhada com ${coletor['responsible']} com sucesso!'),
                  ),
                );
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }
}
