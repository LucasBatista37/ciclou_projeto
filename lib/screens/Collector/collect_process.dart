import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class CollectProcess extends StatefulWidget {
  const CollectProcess({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CollectProcessState createState() => _CollectProcessState();
}

class _CollectProcessState extends State<CollectProcess> {
  final String _endereco = "Rua Monteiro, 123 - São Paulo";
  final String _tipoEstabelecimento = "Restaurante";
  final String _quantidadeEstimativa = "20 Litros";

  double _quantidadeReal = 0.0;
  bool _coletaFinalizada = false;
  String? _caminhoCertificado;

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
            pw.Text('Quantidade Coletada: $_quantidadeReal Litros',
                style: const pw.TextStyle(fontSize: 16)),
            pw.Text('Endereço: $_endereco',
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

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Certificado gerado com sucesso! Salvo em: ${file.path}')),
    );

    _abrirCertificado();
  }

  void _abrirCertificado() {
    if (_caminhoCertificado != null) {
      OpenFile.open(_caminhoCertificado!);
    }
  }

  void _confirmarColeta() {
    setState(() {
      _coletaFinalizada = true;
    });

    _gerarCertificado();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coleta confirmada com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                'Endereço: $_endereco',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Tipo de Estabelecimento: $_tipoEstabelecimento',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Quantidade Estimada: $_quantidadeEstimativa',
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
              const Text(
                'Observações',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Observações sobre a coleta',
                ),
                onChanged: (value) {
                  setState(() {});
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
                  onPressed: _coletaFinalizada
                      ? null
                      : () {
                          _confirmarColeta();
                        },
                  child: const Text(
                    'Confirmar Coleta',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_coletaFinalizada)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.lightGreen,
                      child: const Text(
                        'Coleta finalizada com sucesso! Certificado gerado.',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 12.0),
                      ),
                      onPressed: _abrirCertificado,
                      child: const Text(
                        'Abrir Certificado',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
