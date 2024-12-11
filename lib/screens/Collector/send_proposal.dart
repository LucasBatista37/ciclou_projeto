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
  final TextEditingController _comentariosController = TextEditingController();

  void _enviarProposta() async {
    if (_formKey.currentState!.validate()) {
      final preco = _precoController.text.trim();
      final comentarios = _comentariosController.text.trim();

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

        final requestorId =
            coletaDoc.data()?['userId']; 

        await FirebaseFirestore.instance
            .collection('coletas')
            .doc(widget.documentId)
            .collection('propostas')
            .add({
          'precoPorLitro': preco,
          'comentarios': comentarios,
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
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proposta enviada com sucesso!')),
        );
        Navigator.pop(context);
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
                'Comentários ou Condições Especiais',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                controller: _comentariosController,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Adicione comentários ou condições (opcional)',
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
