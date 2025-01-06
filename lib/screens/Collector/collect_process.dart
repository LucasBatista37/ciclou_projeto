import 'dart:convert';
import 'dart:developer' as developer;
import 'package:ciclou_projeto/components/collect_process/Coleta_info.dart';
import 'package:ciclou_projeto/components/collect_process/Collect_Service.dart';
import 'package:ciclou_projeto/components/collect_process/comprovante_overlay.dart';
import 'package:ciclou_projeto/components/collect_process/generate_certificate.dart';
import 'package:ciclou_projeto/components/scaffold_mensager.dart';
import 'package:ciclou_projeto/screens/Collector/collect_finished.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
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
  String? _qrCodeText;
  String? _confirmationCode;

  double _quantidadeReal = 0.0;
  bool _coletaFinalizada = false;
  String? _paymentStatus;
  File? _comprovantePagamento;
  double _valorTotalPago = 0.0;

  @override
  void initState() {
    super.initState();
    _coletaAtual = widget.coletaAtual;
    _carregando = false;
    _buscarQrCode();
    _verificarPagamento();
    _carregarValorTotalPago();
    developer.log("Coleta inicializada com ID: ${_coletaAtual.id}");
  }

  Future<void> _verificarPagamento() async {
    try {
      final result =
          await CollectService.verificarPagamentoComCodigo(_coletaAtual.id);

      setState(() {
        _paymentStatus = result['paymentStatus'];
        _confirmationCode = result['confirmationCode'];
      });
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Erro ao verificar pagamento: $e',
      );
    }
  }

  Future<void> _carregarValorTotalPago() async {
    try {
      final valor = await CollectService.getValorTotalPago(_coletaAtual.id);
      setState(() {
        _valorTotalPago = valor;
      });
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Erro ao carregar valor total pago: $e',
      );
    }
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
        setState(() {
          _qrCodeBase64 = proposalData['qrCodeBase64'];
          _qrCodeText = proposalData['qrCode'];
        });
      } else {
        developer.log("Nenhuma proposta aceita encontrada.");
      }
    } catch (e) {
      developer.log("Erro ao buscar QR Code da proposta: $e");
    }
  }

  Future<void> _gerarCertificado() async {
    final data = _coletaAtual.data() as Map<String, dynamic>;

    try {
      await CertificadoService.gerarCertificado(
        coletaData: data,
        coletaId: _coletaAtual.id,
        quantidadeReal: _quantidadeReal,
      );

      ScaffoldMessengerHelper.showSuccess(
        context: context,
        message: 'Certificado gerado com sucesso!',
      );
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Erro ao gerar certificado: $e',
      );
    }
  }

  Future<void> _enviarComprovantePagamento() async {
    if (_comprovantePagamento == null) {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Nenhum comprovante selecionado.',
      );

      return;
    }

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuário não autenticado.');
      }

      await FirebaseFirestore.instance
          .collection('coletas')
          .doc(_coletaAtual.id)
          .update({
        'comprovantePagamento': _comprovantePagamento!.path,
      });

      developer.log("Comprovante de pagamento enviado com sucesso.");
      ScaffoldMessengerHelper.showSuccess(
        context: context,
        message: 'Comprovante enviado com sucesso!',
      );

      await _finalizarColeta();
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Erro ao enviar comprovante: $e',
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
    } catch (e, stack) {
      developer.log("Erro ao atualizar quantidade de óleo pelo coletor: $e",
          error: e, stackTrace: stack);
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Erro ao atualizar quantidade de óleo pelo coletor: $e',
      );
    }
  }

  Future<void> _confirmarColeta() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Usuário não autenticado.',
      );
      return;
    }

    final data = _coletaAtual.data() as Map<String, dynamic>;

    if (data['collectorId'] != currentUser.uid) {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Permissão negada para essa coleta.',
      );
      return;
    }

    _mostrarSobreposicaoComprovante();
  }

  Future<void> _finalizarColeta() async {
    try {
      await FirebaseFirestore.instance
          .collection('coletas')
          .doc(_coletaAtual.id)
          .update({
        'status': 'Finalizada',
        'quantidadeReal': _quantidadeReal,
        'dataConclusao': FieldValue.serverTimestamp(),
      });

      final data = _coletaAtual.data() as Map<String, dynamic>;
      final String collectorId = data['collectorId'] ?? '';
      if (collectorId.isNotEmpty) {
        await _atualizarQuantidadeOleo(collectorId);
      }

      setState(() {
        _coletaFinalizada = true;
      });

      ScaffoldMessengerHelper.showSuccess(
        context: context,
        message: 'Coleta confirmada com sucesso!',
      );

      await _gerarCertificado();

      Future.delayed(Duration.zero, () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const ColetaFinalizadaScreen()),
        );
      });
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Erro ao finalizar coleta: $e',
      );
    }
  }

  void _mostrarSobreposicaoComprovante() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ComprovanteOverlay(
          onComprovanteSelecionado: (File? comprovante) {
            setState(() {
              _comprovantePagamento = comprovante;
            });
          },
          onEnviarComprovante: () async {
            await _enviarComprovantePagamento();
            Navigator.pop(context);
          },
        );
      },
    );
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
              ColetaInfoCard(
                tipoEstabelecimento: data['tipoEstabelecimento'] ?? 'N/A',
                quantidadeOleo: (data['quantidadeOleo'] ?? 'N/A').toString(),
                endereco: data['address'],
                mostrarEndereco: _paymentStatus == 'approved',
              ),

              const SizedBox(height: 8),

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
                                Clipboard.setData(
                                  ClipboardData(text: data['chavePix'] ?? ''),
                                );
                                ScaffoldMessengerHelper.showSuccess(
                                  context: context,
                                  message:
                                      'Chave Pix copiada para a área de transferência!',
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
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.monetization_on,
                                color: Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Valor Total Pago:',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              'R\$ ${_valorTotalPago.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
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

              // Exibe o código de confirmação
              if (_confirmationCode != null &&
                  (data['status'] ?? '') != 'Aprovado') ...[
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 3,
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Código de Confirmação da Coleta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _confirmationCode!,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Pagamento Aprovado e Registro da Coleta
              if (_paymentStatus == 'approved' &&
                  (data['status'] ?? '') == 'Aprovado')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Card(
                        color: Colors.green[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: const Text(
                            'Pagamento aprovado e coleta aprovada! Você pode prosseguir com a coleta.',
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
                )
              else if (_paymentStatus == 'approved' &&
                  (data['status'] ?? '') != 'Aprovado')
                Center(
                  child: Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: const Text(
                        'Pagamento aprovado, peça que o solicitante preencha o código acima para poder finalizar a colta.',
                        style: TextStyle(fontSize: 16, color: Colors.green),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

              if (_qrCodeBase64 != null && _paymentStatus != 'approved')
                Center(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 5,
                    shadowColor: Colors.grey.shade300,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Pagamento com QR Code para a Plataforma',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Use o QR Code para efetuar o pagamento para a plataforma, após isso poderá visualizar o endereço e pagar o solicitante.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green, width: 2),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            padding: const EdgeInsets.all(8.0),
                            child: Image.memory(
                              base64Decode(_qrCodeBase64!),
                              width: 200,
                              height: 200,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_qrCodeText != null) ...[
                            const Text(
                              'Código QR:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              padding: const EdgeInsets.all(12.0),
                              child: SelectableText(
                                '${_qrCodeText!.substring(0, 22)}...',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontFamily: 'Courier',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    if (_qrCodeText != null) {
                                      Clipboard.setData(
                                          ClipboardData(text: _qrCodeText!));
                                      ScaffoldMessengerHelper.showSuccess(
                                        context: context,
                                        message: 'Código Copiado!',
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.copy,
                                      color: Colors.white),
                                  label: const Text(
                                    'Copiar Código',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12.0,
                                      horizontal: 16.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    await _verificarPagamento();
                                    ScaffoldMessengerHelper.showWarning(
                                      context: context,
                                      message: 'Revalidando Pagamento...',
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12.0,
                                      horizontal: 16.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  child: const Text(
                                    'Já Paguei',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
