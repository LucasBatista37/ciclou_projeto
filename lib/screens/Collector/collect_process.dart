import 'dart:convert';
import 'dart:developer' as developer;
import 'package:ciclou_projeto/components/collect_process/Coleta_info.dart';
import 'package:ciclou_projeto/components/collect_process/Collect_Service.dart';
import 'package:ciclou_projeto/components/collect_process/Pagamento_info.dart';
import 'package:ciclou_projeto/components/collect_process/Pagamento_plataforma.dart';
import 'package:ciclou_projeto/components/collect_process/comprovante_overlay.dart';
import 'package:ciclou_projeto/components/collect_process/generate_certificate.dart';
import 'package:ciclou_projeto/components/scaffold_mensager.dart';
import 'package:ciclou_projeto/screens/Collector/collect_finished.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  bool _isLoading = false;
  bool _isProcessing = false;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum comprovante selecionado.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuário não autenticado.');
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('comprovantes_pagamento')
          .child('$userId/${DateTime.now().millisecondsSinceEpoch}.pdf');

      final uploadTask = await storageRef.putFile(_comprovantePagamento!);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('coletas')
          .doc(_coletaAtual.id)
          .update({
        'comprovantePagamento': downloadUrl,
      });

      await _finalizarColeta();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Comprovante enviado e coleta finalizada com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Erro ao enviar comprovante ou finalizar coleta: $e')),
      );
    } finally {
      Navigator.pop(context);
      setState(() {
        _isProcessing = false;
      });
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

  Future<void> _notificarSolicitante(BuildContext context) async {
    try {
      final coletaDoc = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(_coletaAtual.id)
          .get();

      if (!coletaDoc.exists) {
        ScaffoldMessengerHelper.showError(
          context: context,
          message: 'Erro: coleta não encontrada.',
        );
        return;
      }

      final requestorId = coletaDoc.data()?['userId'];

      if (requestorId == null) {
        ScaffoldMessengerHelper.showError(
          context: context,
          message: 'Erro: solicitante não encontrado.',
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('coletas')
          .doc(_coletaAtual.id)
          .update({
        'coletorACaminho': true,
        'status': 'Coletor a Caminho',
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'Coletor a Caminho',
        'message': 'O coletor está a caminho da coleta.',
        'timestamp': FieldValue.serverTimestamp(),
        'requestorId': requestorId,
        'coletaId': _coletaAtual.id,
        'isRead': false,
      });

      ScaffoldMessengerHelper.showSuccess(
        context: context,
        message: 'Solicitante notificado que você está a caminho!',
      );

      setState(() {
        _coletaAtual = coletaDoc;
      });
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Erro ao notificar o solicitante: $e',
      );
    }
  }

  Widget _buildEstouIndoButton(BuildContext context) {
    final data = _coletaAtual.data() as Map<String, dynamic>;
    final coletorACaminho = data['coletorACaminho'] ?? false;

    if (coletorACaminho) {
      return const SizedBox.shrink();
    }

    return ElevatedButton(
      onPressed: () async {
        await _notificarSolicitante(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      ),
      child: const Text(
        'Estou indo',
        style: TextStyle(color: Colors.white),
      ),
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

              const SizedBox(height: 24),
              if (_paymentStatus == 'approved' &&
                  (data['status'] ?? '') == 'Aprovado') ...[
                const Text(
                  'Digite a quantidade real coletada',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide:
                          const BorderSide(color: Colors.green, width: 2),
                    ),
                    labelText: 'Quantidade em Litros',
                    labelStyle: const TextStyle(color: Colors.green),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide:
                          const BorderSide(color: Colors.green, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _quantidadeReal = double.tryParse(value) ?? 0.0;

                      double precoPorLitro = double.tryParse(
                              data['precoPorLitro']?.toString() ?? '0.0') ??
                          0.0;

                      _valorTotalPago = _quantidadeReal * precoPorLitro;
                    });
                  },
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'R\$',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      _valorTotalPago.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                if (_paymentStatus == 'approved' &&
                    (data['status'] ?? '') == 'Aprovado' &&
                    _valorTotalPago > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Faça o pagamento de R\$ ${_valorTotalPago.toStringAsFixed(2)} para a chave Pix abaixo.',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],

                // Informações de Pagamento
                PagamentoInfoCard(
                  tipoChavePix: data['tipoChavePix'] ?? 'N/A',
                  chavePix: data['chavePix'] ?? 'N/A',
                  banco: data['banco'] ?? 'N/A',
                  valorTotalPago: _valorTotalPago,
                  onCopiarChavePix: () {
                    Clipboard.setData(
                        ClipboardData(text: data['chavePix'] ?? ''));
                    ScaffoldMessengerHelper.showSuccess(
                      context: context,
                      message:
                          'Chave Pix copiada para a área de transferência!',
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Exibe o código de confirmação
              if (_confirmationCode != null &&
                  (data['status'] ?? '') != 'Aprovado') ...[
                Center(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 3,
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    setState(() {
                                      _isLoading = true;
                                    });

                                    ScaffoldMessengerHelper.showWarning(
                                      context: context,
                                      message: 'Atualizando...',
                                    );

                                    await Future.delayed(
                                        const Duration(seconds: 2));

                                    setState(() {
                                      _isLoading = false;
                                      _verificarPagamento();
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _isLoading ? Colors.grey : Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0, vertical: 12.0),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Já confirmado',
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_confirmationCode != null &&
                  !(data['coletorACaminho'] ?? false) &&
                  (data['status'] ?? '') != 'Aprovado') ...[
                Center(
                  child: ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () async {
                            setState(() {
                              _isProcessing = true;
                            });

                            await _notificarSolicitante(context);

                            final updatedColetaDoc = await FirebaseFirestore
                                .instance
                                .collection('coletas')
                                .doc(_coletaAtual.id)
                                .get();

                            setState(() {
                              _coletaAtual = updatedColetaDoc;
                              _isProcessing = false;
                            });

                            ScaffoldMessengerHelper.showSuccess(
                              context: context,
                              message:
                                  'Solicitante notificado que você está a caminho!',
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 12.0),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Estou indo',
                            style: TextStyle(color: Colors.white),
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
                            'Pagamento aprovado e coleta aprovada! Faça o pagamento para o solicitante para prosseguir com a coleta.',
                            style: TextStyle(fontSize: 16, color: Colors.green),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const Divider(),
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
                          'Já paguei',
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
                        'Pagamento aprovado, peça que o solicitante preencha o código acima para poder prosseguir com a coleta.',
                        style: TextStyle(fontSize: 16, color: Colors.green),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

              if (_qrCodeBase64 != null && _paymentStatus != 'approved')
                PagamentoQRCodeCard(
                  qrCodeBase64: _qrCodeBase64!,
                  qrCodeText: _qrCodeText,
                  onCopiarCodigo: () {
                    if (_qrCodeText != null) {
                      Clipboard.setData(ClipboardData(text: _qrCodeText!));
                      ScaffoldMessengerHelper.showSuccess(
                        context: context,
                        message: 'Código Copiado!',
                      );
                    }
                  },
                  onRevalidarPagamento: () async {
                    await _verificarPagamento();
                    ScaffoldMessengerHelper.showWarning(
                      context: context,
                      message: 'Revalidando Pagamento...',
                    );
                  },
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
