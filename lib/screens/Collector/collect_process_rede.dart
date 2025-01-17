import 'dart:convert';
import 'dart:developer' as developer;
import 'package:ciclou_projeto/components/collect_process/Coleta_info.dart';
import 'package:ciclou_projeto/components/collect_process/Collect_Service.dart';
import 'package:ciclou_projeto/components/collect_process/Pagamento_info.dart';
import 'package:ciclou_projeto/components/collect_process/Pagamento_plataforma.dart';
import 'package:ciclou_projeto/components/collect_process/Pagamento_solicitante.dart';
import 'package:ciclou_projeto/components/collect_process/comprovante_overlay.dart';
import 'package:ciclou_projeto/components/collect_process/generate_certificate.dart';
import 'package:ciclou_projeto/components/payment_service.dart';
import 'package:ciclou_projeto/components/scaffold_mensager.dart';
import 'package:ciclou_projeto/screens/Collector/collect_finished.dart';
import 'package:ciclou_projeto/screens/Collector/share_collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class CollectProcessRede extends StatefulWidget {
  final DocumentSnapshot<Object?> coletaAtual;

  const CollectProcessRede({super.key, required this.coletaAtual});

  @override
  _CollectProcessRedeState createState() => _CollectProcessRedeState();
}

class _CollectProcessRedeState extends State<CollectProcessRede> {
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

  String? _qrCodeSolicitanteBase64;
  String? _qrCodeTextSolicitante;

  @override
  void initState() {
    super.initState();
    _coletaAtual = widget.coletaAtual;
    _carregando = false;
    _buscarQrCode();
    _verificarPagamento();
    _carregarValorTotalPago();
    _loadSolicitanteQRCode(_coletaAtual.id, 'proposalId');
    developer.log("Coleta inicializada com ID: ${_coletaAtual.id}");
  }

  Future<void> _verificarPagamento() async {
    developer.log(
        "Iniciando verificação de pagamento para a coleta ID: ${_coletaAtual.id}");
    try {
      final result =
          await CollectService.verificarPagamentoComCodigo(_coletaAtual.id);

      setState(() {
        _paymentStatus = result['paymentStatus'];
        _confirmationCode = result['confirmationCode'];
      });

      developer.log(
          "Verificação de pagamento concluída com sucesso. Status: $_paymentStatus, Código de confirmação: $_confirmationCode",
          name: "_verificarPagamento");
    } catch (e) {
      developer.log("Erro ao verificar pagamento",
          error: e, name: "_verificarPagamento");
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Erro ao verificar pagamento.',
      );
    }
  }

  Future<void> _loadSolicitanteQRCode(
      String documentId, String proposalId) async {
    developer.log("Carregando QR Code do solicitante...");
    try {
      final propostaData = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(documentId)
          .collection('propostas')
          .doc(proposalId)
          .get();

      if (propostaData.exists) {
        final data = propostaData.data();
        developer.log("Dados da proposta: $data");

        setState(() {
          _qrCodeSolicitanteBase64 = data?['qrCodeTextSolicitante'];
          _qrCodeTextSolicitante = data?['qrCodeSolicitante'];
        });

        developer.log(
            "QR Code do solicitante atualizado: Base64=${_qrCodeSolicitanteBase64}, Text=${_qrCodeTextSolicitante}");
      } else {
        developer
            .log("Proposta não encontrada ou sem QR Code para o solicitante.");
      }
    } catch (e) {
      developer.log("Erro ao carregar QR Code do solicitante: $e");
    }
  }

  Future<void> _carregarValorTotalPago() async {
    developer.log(
        "Carregando valor total pago para a coleta ID: ${_coletaAtual.id}");
    try {
      final valor = await CollectService.getValorTotalPago(_coletaAtual.id);
      setState(() {
        _valorTotalPago = valor;
      });

      developer.log(
          "Valor total pago carregado com sucesso. Valor: $_valorTotalPago",
          name: "_carregarValorTotalPago");
    } catch (e) {
      developer.log("Erro ao carregar valor total pago",
          error: e, name: "_carregarValorTotalPago");
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Erro ao carregar valor total pago.',
      );
    }
  }

  Future<void> _buscarQrCode() async {
    developer.log("Buscando QR Code para a coleta ID: ${_coletaAtual.id}");
    try {
      final proposalSnapshot = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(_coletaAtual.id)
          .collection('propostas')
          .where('status', isEqualTo: 'Aceita')
          .get();

      if (proposalSnapshot.docs.isNotEmpty) {
        final proposalData = proposalSnapshot.docs.first.data();
        final proposalId = proposalSnapshot.docs.first.id;

        setState(() {
          _qrCodeBase64 = proposalData['qrCodeBase64'];
          _qrCodeText = proposalData['qrCode'];
        });

        developer.log("QR Code encontrado: $_qrCodeBase64",
            name: "_buscarQrCode");

        await _loadSolicitanteQRCode(_coletaAtual.id, proposalId);
      } else {
        developer.log(
            "Nenhuma proposta aceita encontrada para a coleta ID: ${_coletaAtual.id}",
            name: "_buscarQrCode");
      }
    } catch (e) {
      developer.log("Erro ao buscar QR Code da proposta",
          error: e, name: "_buscarQrCode");
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
        message: 'Erro ao gerar certificado.',
      );
    }
  }

  Future<void> _enviarComprovantePagamento() async {
    if (_comprovantePagamento == null) {
      ScaffoldMessengerHelper.showWarning(
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

      ScaffoldMessengerHelper.showSuccess(
        context: context,
        message: 'Comprovante enviado com sucesso!',
      );

      await _finalizarColeta();
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Erro ao enviar comprovante.',
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
      developer.log("Erro ao atualizar quantidade de óleo pelo coletor.",
          error: e, stackTrace: stack);
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Erro ao atualizar quantidade de óleo pelo coletor.',
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
        message: 'Erro ao finalizar coleta.',
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
          'Processo de Coleta Rede',
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
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('coletas')
                    .doc(_coletaAtual.id)
                    .collection('propostas')
                    .where('isShared', isEqualTo: true)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const SizedBox(); 
                  }

                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      color: Colors.amber.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: const [
                            Icon(Icons.warning, color: Colors.amber),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Esta coleta é compartilhada.',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return const SizedBox(); 
                },
              ),

              ColetaInfoCard(
                tipoEstabelecimento: data['tipoEstabelecimento'] ?? 'N/A',
                quantidadeOleo: (data['quantidadeOleo'] ?? 'N/A').toString(),
                endereco: data['address'],
                mostrarEndereco: _paymentStatus == 'approved',
              ),

              const SizedBox(height: 8),

              // Informações de Pagamento
              if (_paymentStatus == 'approved' &&
                  _qrCodeSolicitanteBase64 != null &&
                  _qrCodeTextSolicitante != null)
                Column(
                  children: [
                    PagamentoSolicitanteQRCodeCard(
                      qrCodeSolicitanteBase64: _qrCodeSolicitanteBase64!,
                      qrCodeTextSolicitante: _qrCodeTextSolicitante!,
                      onCopiarCodigoSolicitante: () {
                        Clipboard.setData(
                          ClipboardData(text: _qrCodeTextSolicitante!),
                        );
                        ScaffoldMessengerHelper.showSuccess(
                          context: context,
                          message: 'Código Copiado!',
                        );
                        developer
                            .log("Código Pix copiado: $_qrCodeTextSolicitante");
                      },
                      onConfirmarPagamentoSolicitante: () async {
                        developer.log(
                            "Iniciando verificação de pagamento para o solicitante...");
                        ScaffoldMessengerHelper.showWarning(
                          context: context,
                          message: 'Verificando pagamento...',
                        );

                        try {
                          final proposalSnapshot = await FirebaseFirestore
                              .instance
                              .collection('coletas')
                              .doc(_coletaAtual.id)
                              .collection('propostas')
                              .where('status', isEqualTo: 'Aceita')
                              .get();

                          if (proposalSnapshot.docs.isNotEmpty) {
                            final proposalData =
                                proposalSnapshot.docs.first.data();
                            final proposalId = proposalSnapshot.docs.first.id;
                            final paymentIdSolicitante =
                                proposalData['paymentIdSolicitante'];

                            developer.log(
                                "Usando paymentIdSolicitante: $paymentIdSolicitante");

                            final paymentService =
                                PaymentService(paymentIdSolicitante);
                            final paymentStatus =
                                await paymentService.validatePayment();

                            developer.log(
                                "Resposta da validação de pagamento: $paymentStatus");

                            if (paymentStatus == 'approved') {
                              await FirebaseFirestore.instance
                                  .collection('coletas')
                                  .doc(_coletaAtual.id)
                                  .collection('propostas')
                                  .doc(proposalId)
                                  .update({'statusSolicitante': 'Aprovado'});

                              setState(() {
                                _paymentStatus = 'approved';
                              });

                              ScaffoldMessengerHelper.showSuccess(
                                context: context,
                                message: 'Pagamento ao solicitante confirmado!',
                              );
                              developer.log(
                                  "Pagamento confirmado e statusSolicitante atualizado para 'Aprovado'.");
                            } else {
                              ScaffoldMessengerHelper.showWarning(
                                context: context,
                                message:
                                    'Pagamento ainda não foi aprovado.',
                              );
                              developer.log(
                                  "Pagamento ainda não aprovado.");
                            }
                          } else {
                            ScaffoldMessengerHelper.showError(
                              context: context,
                              message: 'Nenhuma proposta aceita encontrada.',
                            );
                            developer
                                .log("Nenhuma proposta aceita encontrada.");
                          }
                        } catch (e, stackTrace) {
                          ScaffoldMessengerHelper.showError(
                            context: context,
                            message: 'Erro ao verificar pagamento.',
                          );
                          developer.log("Erro ao verificar pagamento.",
                              error: e, stackTrace: stackTrace);
                        }
                      },
                    ),
                  ],
                ),

              const SizedBox(height: 8),

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

              const SizedBox(height: 16),

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
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Botão Compartilhar Coleta
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CompartilharColetaScreen(
                          coletaId: _coletaAtual.id,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: const Text(
                    'Compartilhar Coleta',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
                        'Pagamento aprovado, peça que o solicitante preencha o código acima para poder finalizar a coleta.',
                        style: TextStyle(fontSize: 16, color: Colors.green),
                        textAlign: TextAlign.center,
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
