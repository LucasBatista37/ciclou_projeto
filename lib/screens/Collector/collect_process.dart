import 'dart:developer' as developer;
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
    developer.log("Coleta inicializada com ID: ${_coletaAtual.id}");
  }

  Future<void> _atualizarQuantidadeOleo(String collectorId) async {
    developer.log("Atualizando quantidade de óleo pelo coletor...");
    try {
      final collectorDocRef =
          FirebaseFirestore.instance.collection('collector').doc(collectorId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(collectorDocRef);

        final currentAmountRaw = snapshot.data()?['amountOil'] ?? 0.0;
        final double currentAmount = currentAmountRaw is double
            ? currentAmountRaw
            : double.tryParse(currentAmountRaw.toString()) ?? 0.0;

        final newAmount = currentAmount + _quantidadeReal;

        transaction.update(collectorDocRef, {'amountOil': newAmount});
      });

      developer.log(
          "Quantidade de óleo coletada foi atualizada com sucesso pelo coletor.");
    } catch (e, stack) {
      developer.log("Erro ao atualizar quantidade de óleo pelo coletor: $e",
          error: e, stackTrace: stack);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Erro ao atualizar quantidade de óleo pelo coletor: $e')),
      );
    }
  }

  Future<void> _confirmarColeta() async {
    developer.log("Iniciando confirmação da coleta...");

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      developer.log("Erro: Usuário não autenticado.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado.')),
      );
      return;
    }

    final data = _coletaAtual.data() as Map<String, dynamic>;

    if (data['collectorId'] != currentUser.uid) {
      developer.log(
          "Erro: Permissão negada. O coletor não corresponde ao usuário atual.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissão negada para esta coleta.')),
      );
      return;
    }

    try {
      developer.log("Atualizando coleta no Firestore...");
      await FirebaseFirestore.instance
          .collection('coletas')
          .doc(_coletaAtual.id)
          .update({
        'status': 'Finalizada',
        'quantidadeReal': _quantidadeReal,
        'dataConclusao': FieldValue.serverTimestamp(),
      });

      developer
          .log("Atualizando a quantidade de óleo no registro do coletor...");
      await _atualizarQuantidadeOleo(currentUser.uid);

      setState(() {
        _coletaFinalizada = true;
      });

      developer.log("Coleta confirmada com sucesso pelo coletor.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coleta confirmada com sucesso!')),
      );

      await _gerarCertificado();
    } catch (e, stack) {
      developer.log("Erro ao confirmar coleta: $e",
          error: e, stackTrace: stack);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao confirmar coleta: $e')),
      );
    }
  }

  Future<void> _gerarCertificado() async {
    developer.log("Iniciando geração do certificado...");
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      developer.log("Erro: Usuário não autenticado para gerar certificado.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado.')),
      );
      return;
    }

    final data = _coletaAtual.data() as Map<String, dynamic>;

    try {
      developer.log("Dados da coleta: $data");

      final templatePdf = await rootBundle.load('assets/certificado.png');
      developer.log("Imagem do certificado carregada com sucesso.");

      final outputPdf = pw.Document();

      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final ttf = pw.Font.ttf(fontData.buffer.asByteData());

      final pdfImage = pw.MemoryImage(templatePdf.buffer.asUint8List());

      outputPdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(792, 612),
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Stack(
              children: [
                pw.Image(pdfImage, fit: pw.BoxFit.cover),
                pw.Positioned(
                  left: 125,
                  top: 272,
                  child: pw.Text(
                    '${data['tipoEstabelecimento'] ?? 'N/A'}',
                    style: pw.TextStyle(font: ttf, fontSize: 18),
                  ),
                ),
                pw.Positioned(
                  left: 98,
                  top: 314,
                  child: pw.Text(
                    '${data['cnpj'] ?? 'N/A'}',
                    style: pw.TextStyle(font: ttf, fontSize: 18),
                  ),
                ),
                pw.Positioned(
                  left: 260,
                  top: 360,
                  child: pw.Text(
                    '${_quantidadeReal.toStringAsFixed(2)} L',
                    style: pw.TextStyle(font: ttf, fontSize: 18),
                  ),
                ),
                pw.Positioned(
                  left: 390,
                  top: 360,
                  child: pw.Text(
                    '${DateTime.now().toString().split(' ')[0]}',
                    style: pw.TextStyle(font: ttf, fontSize: 18),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/certificado_${_coletaAtual.id}.pdf');
      await file.writeAsBytes(await outputPdf.save());

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

      developer.log("Certificado gerado e salvo com sucesso: ${file.path}");
      _abrirCertificado();
    } catch (e, stack) {
      developer.log("Erro ao gerar certificado: $e",
          error: e, stackTrace: stack);
    }
  }

  void _abrirCertificado() {
    if (_caminhoCertificado != null) {
      developer.log("Abrindo certificado: $_caminhoCertificado");
      OpenFile.open(_caminhoCertificado!);
    } else {
      developer.log("Erro: Caminho do certificado está vazio.");
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
