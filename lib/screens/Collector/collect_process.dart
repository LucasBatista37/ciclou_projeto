import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CollectProcess extends StatefulWidget {
  const CollectProcess({super.key});

  @override
  _CollectProcessState createState() => _CollectProcessState();
}

class _CollectProcessState extends State<CollectProcess> {
  DocumentSnapshot? _coletaAtual; 
  bool _carregando = true;
  String? _caminhoCertificado;

  double _quantidadeReal = 0.0;
  bool _coletaFinalizada = false;

  @override
  void initState() {
    super.initState();
    _carregarColetaEmAndamento();
  }

  Future<void> _carregarColetaEmAndamento() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('coletas')
          .where('status', isEqualTo: 'Em andamento')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _coletaAtual = querySnapshot.docs.first;
          _carregando = false;
        });
      } else {
        setState(() {
          _carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        _carregando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar coleta: $e')),
      );
    }
  }

  Future<void> _confirmarColeta() async {
    if (_coletaAtual == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('coletas')
          .doc(_coletaAtual!.id)
          .update({'status': 'Finalizada', 'quantidadeReal': _quantidadeReal});

      await _gerarCertificado();

      setState(() {
        _coletaFinalizada = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coleta confirmada com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao confirmar coleta: $e')),
      );
    }
  }

  Future<void> _gerarCertificado() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Certificado de Destinação Final',
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Text('Coletor: João da Silva',
                style: const pw.TextStyle(fontSize: 16)),
            pw.Text('Data: ${DateTime.now().toString().split(' ')[0]}',
                style: const pw.TextStyle(fontSize: 16)),
            pw.Text(
                'Quantidade Coletada: ${_quantidadeReal.toStringAsFixed(2)} Litros',
                style: const pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 16),
            pw.Text(
              'Este certificado comprova que o óleo coletado foi devidamente destinado, contribuindo para a sustentabilidade ambiental.',
              style: const pw.TextStyle(
                  fontSize: 14, color: PdfColor.fromInt(0xFF888888)),
            ),
          ],
        ),
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/certificado.pdf');
    await file.writeAsBytes(await pdf.save());

    setState(() {
      _caminhoCertificado = file.path;
    });

    _abrirCertificado();
  }

  void _abrirCertificado() {
    if (_caminhoCertificado != null) {
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
                'Tipo de Estabelecimento: ${_coletaAtual?['tipoEstabelecimento'] ?? 'N/A'}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Quantidade Estimada: ${_coletaAtual?['quantidadeOleo'] ?? 'N/A'} Litros',
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
