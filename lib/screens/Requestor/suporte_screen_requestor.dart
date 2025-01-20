import 'package:ciclou_projeto/components/scaffold_mensager.dart';
import 'package:ciclou_projeto/screens/Requestor/requestor_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:ciclou_projeto/models/user_model.dart';

class SupportScreenRequestor extends StatefulWidget {
  final UserModel user;

  const SupportScreenRequestor({super.key, required this.user});

  @override
  _SupportScreenRequestorState createState() => _SupportScreenRequestorState();
}

class _SupportScreenRequestorState extends State<SupportScreenRequestor> {
  final TextEditingController _commentController = TextEditingController();
  String _selectedType = "Transação";

  Future<void> _sendEmail() async {
    if (_commentController.text.isEmpty) {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Por favor, preencha todos os campos.',
      );
      return;
    }

    final Email email = Email(
      body: 'Tipo: $_selectedType\n\nComentário:\n${_commentController.text}',
      subject: '[$_selectedType] Novo Relato de Suporte',
      recipients: ['suporteciclou@gmail.com'],
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
      ScaffoldMessengerHelper.showSuccess(
        context: context,
        message: 'Mensagem enviada com sucesso!',
      );
      _commentController.clear();
    } on PlatformException catch (e) {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Erro ao enviar mensagem.',
      );
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Erro ao enviar mensagem.',
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
          'Suporte',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RequestorDashboard(user: widget.user),
              ),
            );
          },
        ),
      ),
      body: _buildSupportBody(),
    );
  }

  Widget _buildSupportBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Envie-nos sua dúvida ou problema',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: const [
                DropdownMenuItem(value: 'Transação', child: Text('Transação')),
                DropdownMenuItem(
                    value: 'Suporte Técnico', child: Text('Suporte Técnico')),
                DropdownMenuItem(
                    value: 'Usabilidade', child: Text('Usabilidade')),
                DropdownMenuItem(value: 'Outro', child: Text('Outro')),
              ],
              decoration: InputDecoration(
                labelText: 'Tipo',
                labelStyle: const TextStyle(fontSize: 16, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Comentário',
                labelStyle: const TextStyle(fontSize: 16, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 64.0, vertical: 12.0),
                ),
                onPressed: _sendEmail,
                child: const Text(
                  'Enviar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
