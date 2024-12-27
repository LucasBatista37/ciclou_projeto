import 'package:ciclou_projeto/screens/Collector/collector_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ciclou_projeto/models/user_model.dart';

class SendProposal extends StatefulWidget {
  final String documentId;
  final UserModel user;

  const SendProposal({super.key, required this.documentId, required this.user});

  @override
  _SendProposalState createState() => _SendProposalState();
}

class _SendProposalState extends State<SendProposal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _precoController = TextEditingController();
  String _tempoRestante = '';
  final List<int> _temposMaximos = [2, 6, 12, 24, 36, 48];
  int? _tempoMaximoSelecionado;

  double _quantidadeOleo = 0.0; // Armazena o valor de quantidadeOleo
  double _totalCalculado = 0.0; // Armazena o total calculado
  double _taxa = 0.0; // Armazena a taxa da plataforma

  @override
  void initState() {
    super.initState();
    _calcularTempoRestante();
    _buscarQuantidadeOleo();
  }

  Future<void> _buscarQuantidadeOleo() async {
    try {
      final coletaDoc = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(widget.documentId)
          .get();

      if (coletaDoc.exists) {
        final quantidade = coletaDoc.data()?['quantidadeOleo'];
        if (quantidade != null) {
          setState(() {
            _quantidadeOleo = double.tryParse(quantidade.toString()) ?? 0.0;
            _calcularTotal();
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar quantidade de óleo: $e')),
      );
    }
  }

  double _calcularTaxa(double liters) {
    if (liters >= 20 && liters <= 30) return 7.5;
    if (liters > 30 && liters <= 45) return 10.0;
    if (liters > 45 && liters <= 60) return 12.0;
    if (liters > 60 && liters <= 75) return 14.0;
    if (liters > 75 && liters <= 100) return 16.0;
    return 0.0;
  }

  void _calcularTotal() {
    final preco = double.tryParse(_precoController.text) ?? 0.0;
    setState(() {
      _taxa = _calcularTaxa(_quantidadeOleo);
      _totalCalculado = (preco * _quantidadeOleo) + _taxa;
    });
  }

  Future<void> _calcularTempoRestante() async {
    try {
      final coletaDoc = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(widget.documentId)
          .get();

      if (coletaDoc.exists) {
        final prazoString = coletaDoc.data()?['prazo'];
        if (prazoString != null) {
          final prazo = DateTime.parse(prazoString);
          final agora = DateTime.now();
          final duracao = prazo.difference(agora);

          if (duracao.isNegative) {
            setState(() {
              _tempoRestante = 'Tempo expirado';
            });
          } else {
            final minutosRestantes = duracao.inMinutes;
            setState(() {
              _tempoRestante = '$minutosRestantes min faltando';
            });
          }
        } else {
          setState(() {
            _tempoRestante = 'Prazo não definido';
          });
        }
      }
    } catch (e) {
      setState(() {
        _tempoRestante = 'Erro ao calcular tempo';
      });
    }
  }

  void _enviarProposta() async {
    if (_formKey.currentState!.validate()) {
      final preco = _precoController.text.trim();
      final valorTotalPago = _quantidadeOleo *
          (double.tryParse(preco) ??
              0.0); // Calcula o valor total pago sem a taxa

      try {
        final coletaDoc = await FirebaseFirestore.instance
            .collection('coletas')
            .doc(widget.documentId)
            .get();

        if (!coletaDoc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro: Coleta não encontrada.')),
          );
          return;
        }

        final requestorId = coletaDoc.data()?['userId'];
        final solicitationTitle = coletaDoc.data()?['titulo'] ?? 'Coleta';

        await FirebaseFirestore.instance
            .collection('coletas')
            .doc(widget.documentId)
            .collection('propostas')
            .add({
          'precoPorLitro': preco,
          'status': 'Pendente',
          'criadoEm': FieldValue.serverTimestamp(),
          'tempoMaximoColeta': _tempoMaximoSelecionado,
          'collectorName': widget.user.responsible,
          'collectorId': widget.user.userId,
          'photoUrl': widget.user.photoUrl,
          'valorTotalPago': valorTotalPago
              .toStringAsFixed(2), // Adiciona o valor total pago sem taxa
        });

        await FirebaseFirestore.instance.collection('notifications').add({
          'title': 'Nova Proposta Recebida!',
          'message':
              '${widget.user.responsible} enviou uma proposta para sua solicitação.',
          'timestamp': FieldValue.serverTimestamp(),
          'requestorId': requestorId,
          'coletaId': widget.documentId,
          'solicitationTitle': solicitationTitle,
          'user': widget.user.toMap(),
          'isRead': false,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proposta enviada com sucesso!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => CollectorDashboard(user: widget.user)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar proposta: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text(
          'Enviar Proposta',
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Preço por Litro (R\$)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                controller: _precoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Digite o preço por litro',
                ),
                onChanged: (value) {
                  _calcularTotal();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite o preço';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Digite um valor numérico válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Tempo Máximo de Coleta (horas)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              DropdownButtonFormField<int>(
                value: _tempoMaximoSelecionado,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: _temposMaximos
                    .map(
                      (tempo) => DropdownMenuItem<int>(
                        value: tempo,
                        child: Text('$tempo horas'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _tempoMaximoSelecionado = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Por favor, selecione o tempo máximo de coleta';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.lightGreen.shade100,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tempo Restante:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      '$_tempoRestante',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Quantidade de Óleo:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$_quantidadeOleo litros',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black87),
                        ),
                      ],
                    ),
                    const Divider(height: 24.0, thickness: 1.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Taxa da Plataforma:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'R\$ ${_taxa.toStringAsFixed(2)}',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.red),
                        ),
                      ],
                    ),
                    const Divider(height: 24.0, thickness: 1.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Calculado:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'R\$ ${_totalCalculado.toStringAsFixed(2)}',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.blue),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 12.0),
                  ),
                  onPressed: _enviarProposta,
                  child: const Text(
                    'Enviar Proposta',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
