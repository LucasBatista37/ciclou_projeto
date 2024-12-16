import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CollectProcess extends StatefulWidget {
  final DocumentSnapshot<Object?> coletaAtual;

  const CollectProcess({super.key, required this.coletaAtual});

  @override
  _CollectProcessState createState() => _CollectProcessState();
}

class _CollectProcessState extends State<CollectProcess> {
  late DocumentSnapshot _coletaAtual;
  bool _carregando = true;
  String? _caminhoCertificado;

  double _quantidadeReal = 0.0;
  bool _coletaFinalizada = false;

  @override
  void initState() {
    super.initState();
    _coletaAtual = widget.coletaAtual;
    _carregando = false;
  }

  Future<void> _confirmarColeta() async {
    print("Iniciando processo de confirmação da coleta.");
    if (_coletaAtual == null) {
      print("Erro: Coleta não encontrada.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coleta não encontrada.')),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      print("Erro: Usuário não autenticado.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado.')),
      );
      return;
    }

    final data = _coletaAtual.data() as Map<String, dynamic>;

    print("Dados do Firestore: $data");
    print("UID do usuário autenticado: ${currentUser.uid}");

    print("Verificando permissões...");
    if (data['collectorId'] != currentUser.uid) {
      print(
          "Erro: Permissão negada. UID Firestore (collectorId): ${data['collectorId']}, UID atual: ${currentUser.uid}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Permissão negada para atualizar esta coleta.')),
      );
      return;
    }

    try {
      print("Atualizando o status da coleta no Firestore...");
      await FirebaseFirestore.instance
          .collection('coletas')
          .doc(_coletaAtual.id)
          .update({
        'status': 'Finalizada',
        'quantidadeReal': _quantidadeReal,
      });
      print("Status da coleta atualizado com sucesso.");

      final requestorId = data['userId'];
      if (requestorId != null) {
        print("Enviando notificação para o solicitante...");
        await FirebaseFirestore.instance.collection('notifications').add({
          'title': 'Coleta Finalizada',
          'message': 'A coleta foi finalizada com sucesso.',
          'timestamp': FieldValue.serverTimestamp(),
          'requestorId': requestorId,
          'coletaId': _coletaAtual.id,
          'isRead': false,
        });
        print("Notificação enviada.");
      }

      print("Gerando certificado...");
      await _gerarCertificado();

      setState(() {
        _coletaFinalizada = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coleta confirmada com sucesso!')),
      );
    } catch (e) {
      print("Erro ao confirmar coleta: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao confirmar coleta: $e')),
      );
    }
  }

  Future<void> _gerarCertificado() async {
    print("Iniciando geração do certificado...");
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      print("Erro: Usuário não autenticado para gerar certificado.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado.')),
      );
      return;
    }

    final pdf = pw.Document();

    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData.buffer.asByteData());

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Certificado de Destinação Final',
                style: pw.TextStyle(
                    font: ttf, fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Text('Coletor: ${currentUser.displayName ?? 'Coletor Anônimo'}',
                style: pw.TextStyle(font: ttf, fontSize: 16)),
            pw.Text('Data: ${DateTime.now().toString().split(' ')[0]}',
                style: pw.TextStyle(font: ttf, fontSize: 16)),
            pw.Text(
                'Quantidade Coletada: ${_quantidadeReal.toStringAsFixed(2)} Litros',
                style: pw.TextStyle(font: ttf, fontSize: 16)),
            pw.SizedBox(height: 16),
            pw.Text(
              'Este certificado comprova que o óleo coletado foi devidamente destinado, contribuindo para a sustentabilidade ambiental.',
              style: pw.TextStyle(
                  font: ttf, fontSize: 14, color: PdfColor.fromInt(0xFF888888)),
            ),
          ],
        ),
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/certificado_${_coletaAtual.id}.pdf');
    await file.writeAsBytes(await pdf.save());

    print("Salvando certificado no Firestore...");
    await FirebaseFirestore.instance
        .collection('certificados')
        .doc(_coletaAtual.id)
        .set({
      'coletaId': _coletaAtual.id,
      'userId': currentUser.uid,
      'filePath': file.path,
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      _caminhoCertificado = file.path;
    });

    print("Certificado gerado e salvo com sucesso.");
    _abrirCertificado();
  }

  void _abrirCertificado() {
    if (_caminhoCertificado != null) {
      print("Abrindo o certificado gerado...");
      OpenFile.open(_caminhoCertificado!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_coletaAtual == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Nenhuma coleta em andamento.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    final data = _coletaAtual.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text(
          'Processo de Coleta',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tipo de Estabelecimento: ${data['tipoEstabelecimento'] ?? 'N/A'}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Quantidade Estimada: ${data['quantidadeOleo'] ?? 'N/A'} Litros',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Registrar Quantidade Real Coletada',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Quantidade em Litros',
                ),
                onChanged: (value) {
                  setState(() {
                    _quantidadeReal = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 12.0),
                  ),
                  onPressed: _coletaFinalizada ? null : _confirmarColeta,
                  child: const Text(
                    'Confirmar Coleta',
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
