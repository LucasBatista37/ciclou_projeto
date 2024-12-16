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

  @override
  void initState() {
    super.initState();
    _calcularTempoRestante();
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

        await FirebaseFirestore.instance
            .collection('coletas')
            .doc(widget.documentId)
            .collection('propostas')
            .add({
          'precoPorLitro': preco,
          'status': 'Pendente',
          'criadoEm': FieldValue.serverTimestamp(),
          'collectorName': widget.user.responsible,
          'collectorId': widget.user.userId,
          'photoUrl': widget.user.photoUrl,
        });

        await FirebaseFirestore.instance.collection('notifications').add({
          'title': 'Nova Proposta Recebida!',
          'message':
              '${widget.user.responsible} enviou uma proposta para sua solicitação.',
          'timestamp': FieldValue.serverTimestamp(),
          'requestorId': requestorId,
          'solicitationId': widget.documentId,
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
          'Enviar Proposta (Coletor)',
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
              Text(
                'Tempo disponível para enviar a proposta: $_tempoRestante',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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