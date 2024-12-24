import 'dart:convert';
import 'dart:developer' as developer;
import 'package:ciclou_projeto/components/generate_manualqr_payment.dart';
import 'package:ciclou_projeto/components/payment_service.dart';
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
  String? _qrCodeBase64;

  double _quantidadeReal = 0.0;
  bool _coletaFinalizada = false;
  String? _paymentStatus;

  @override
  void initState() {
    super.initState();
    _coletaAtual = widget.coletaAtual;
    _carregando = false;
    _buscarQrCode();
    _verificarPagamento();
    developer.log("Coleta inicializada com ID: ${_coletaAtual.id}");
  }

  Future<void> _verificarPagamento() async {
    try {
      final proposalSnapshot = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(_coletaAtual.id)
          .collection('propostas')
          .where('status', isEqualTo: 'Aceita')
          .get();

      if (proposalSnapshot.docs.isNotEmpty) {
        final proposalData = proposalSnapshot.docs.first.data();
        final paymentId = proposalData['paymentId'];

        if (paymentId != null) {
          final paymentService = PaymentService(paymentId);

          final status = await paymentService.validatePayment();

          setState(() {
            _paymentStatus = status;
          });

          developer.log("Status do pagamento: $status");

          if (_paymentStatus == 'approved') {
            final confirmationCode = await _generateConfirmationCode();
            _exibirCodigoConfirmacao(confirmationCode);
          }
        } else {
          developer.log("Nenhum ID de pagamento encontrado na proposta.");
        }
      }
    } catch (e, stack) {
      developer.log("Erro ao verificar status do pagamento: $e",
          error: e, stackTrace: stack);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao verificar status do pagamento: $e')),
      );
    }
  }

  Future<String> _generateConfirmationCode() async {
    try {
      final data = _coletaAtual.data() as Map<String, dynamic>;

      // Gera o código de confirmação usando a função importada
      final result = await generateManualQr(
        pixKey: data['chavePix'],
        amount: data['quantidadeOleo'] ?? 0.0,
        description:
            'Confirmação de coleta para ${data['tipoEstabelecimento']}',
      );

      final confirmationCode = result['confirmationCode'] as String;

      // Salva o código de confirmação na coleta no Firestore
      await FirebaseFirestore.instance
          .collection('coletas')
          .doc(_coletaAtual.id)
          .update({
        'confirmationCode': confirmationCode,
      });

      developer.log(
          "Código de confirmação salvo com sucesso na coleta ${_coletaAtual.id}");

      return confirmationCode;
    } catch (e) {
      developer.log("Erro ao gerar código de confirmação: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar código de confirmação: $e')),
      );
      return 'Erro';
    }
  }

  void _exibirCodigoConfirmacao(String confirmationCode) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Código de Confirmação'),
          content: Text(
            confirmationCode,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _buscarQrCode() async {
    try {
      final proposalSnapshot = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(_coletaAtual.id)
          .collection('propostas')
          .where('status', isEqualTo: 'Aceita')
          .get();

      if (proposalSnapshot.docs.isNotEmpty) {
        final proposalData = proposalSnapshot.docs.first.data();
        if (proposalData.containsKey('qrCodeBase64')) {
          setState(() {
            _qrCodeBase64 = proposalData['qrCodeBase64'];
          });
          developer.log("QR Code encontrado e carregado com sucesso.");
        } else {
          developer.log("QR Code não encontrado na proposta aceita.");
        }
      } else {
        developer.log("Nenhuma proposta aceita encontrada.");
      }
    } catch (e) {
      developer.log("Erro ao buscar QR Code da proposta: $e");
    }
  }

  void _exibirQrCode() {
    if (_qrCodeBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR Code não disponível.')),
      );
      return;
    }

    final Uint8List qrCodeBytes = base64Decode(_qrCodeBase64!);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('QR Code para Pagamento'),
          content: Image.memory(qrCodeBytes),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
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

  Future<void> _gerarCertificado() async {
    developer.log("Iniciando geração do certificado...");

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
                  left: 99.5,
                  top: 314.2,
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
        'userId': data['userId'],
        'collectorId': FirebaseAuth.instance.currentUser?.uid,
        'requestorName': data['requestorName'],
        'filePath': file.path,
        'createdAt': FieldValue.serverTimestamp(),
      });

      developer.log(
          "Certificado gerado e associado ao usuário ${data['requestorName']} (ID: ${data['userId']}).");
    } catch (e, stack) {
      developer.log("Erro ao gerar certificado: $e",
          error: e, stackTrace: stack);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar certificado: $e')),
      );
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
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informações da Coleta',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tipo de Estabelecimento: ${data['tipoEstabelecimento'] ?? 'N/A'}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Quantidade Estimada: ${data['quantidadeOleo'] ?? 'N/A'} Litros',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (_paymentStatus == 'approved') ...[
                        const SizedBox(height: 8),
                        Text(
                          'Endereço: ${data['address'] ?? 'N/A'}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Informações de Pagamento
              if (_paymentStatus == 'approved')
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pagamento para o Solicitante',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            const Icon(
                              Icons.attach_money,
                              color: Colors.green,
                              size: 24,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.key, color: Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${data['tipoChavePix'] ?? 'N/A'} / ${data['chavePix'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy,
                                  color: Colors.grey, size: 20),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                    text: data['chavePix'] ?? ''));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Chave Pix copiada para a área de transferência!'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.account_balance,
                                color: Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Banco: ${data['banco'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Por favor, revise cuidadosamente as informações.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Pagamento Aprovado e Registro da Coleta
              if (_paymentStatus == 'approved')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Card(
                        color: Colors.green[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: const Text(
                            'Pagamento aprovado com sucesso! Você pode prosseguir com a coleta.',
                            style: TextStyle(fontSize: 16, color: Colors.green),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Registrar Quantidade Real Coletada',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                          'Finalizar Coleta',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),

              if (_qrCodeBase64 != null && _paymentStatus != 'approved')
                Center(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'QR Code para Pagamento da Plataforma',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Image.memory(
                            base64Decode(_qrCodeBase64!),
                            width: 200,
                            height: 200,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              await _verificarPagamento();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Revalidando status do pagamento...'),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            child: const Text('Já Paguei'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (_qrCodeBase64 == null && _paymentStatus != 'approved')
                const Center(
                  child: Text(
                    'QR Code não disponível.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),

              if (_paymentStatus == 'pending')
                Center(
                  child: Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: const Text(
                        'Pagamento pendente. Por favor, conclua o pagamento para continuar.',
                        style: TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

              if (_paymentStatus == 'rejected')
                Center(
                  child: Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: const Text(
                        'Pagamento rejeitado. Entre em contato com o suporte.',
                        style: TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
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
