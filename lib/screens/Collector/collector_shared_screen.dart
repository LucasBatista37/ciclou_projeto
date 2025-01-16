import 'package:ciclou_projeto/screens/Collector/collect_process_rede.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'dart:developer' as developer;

class ColetorNotificacaoScreen extends StatefulWidget {
  final String coletaId;

  const ColetorNotificacaoScreen({Key? key, required this.coletaId})
      : super(key: key);

  @override
  State<ColetorNotificacaoScreen> createState() =>
      _ColetorNotificacaoScreenState();
}

class _ColetorNotificacaoScreenState extends State<ColetorNotificacaoScreen> {
  Map<String, dynamic>? coleta;
  bool _loading = true;

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _placaController = TextEditingController();
  final TextEditingController _veiculoController = TextEditingController();

  String? _nomeError;
  String? _cpfError;
  String? _placaError;
  String? _veiculoError;

  final maskFormatterCPF = MaskTextInputFormatter(mask: '###.###.###-##');

  @override
  void initState() {
    super.initState();
    developer
        .log('Iniciando ColetorNotificacaoScreen com ID: ${widget.coletaId}');
    _fetchColeta();
  }

  Future<void> _fetchColeta() async {
    developer.log('Buscando coleta com ID: ${widget.coletaId}');

    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(widget.coletaId)
          .get();

      if (snapshot.exists) {
        developer.log('Coleta encontrada: ${snapshot.data()}');
        setState(() {
          coleta = snapshot.data() as Map<String, dynamic>?;
          _loading = false;
        });
      } else {
        developer.log('Coleta não encontrada.');
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coleta não encontrada.')),
        );
      }
    } catch (e, stackTrace) {
      developer.log('Erro ao buscar coleta: $e',
          error: e, stackTrace: stackTrace);
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar coleta: $e')),
      );
    }
  }

  Future<void> _salvarDadosColeta() async {
    if (!_validarCampos()) {
      developer.log('Validação de campos falhou.', name: 'Salvar Coleta');
      return;
    }

    try {
      developer.log(
        'Buscando documento na subcoleção "propostas" com status "Aceita".',
        name: 'Salvar Coleta',
      );

      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(widget.coletaId)
          .collection('propostas')
          .where('status', isEqualTo: 'Aceita')
          .get();

      if (query.docs.isNotEmpty) {
        QueryDocumentSnapshot doc = query.docs.first;

        String idReal = doc.id;
        developer.log(
            'Documento com status "Aceita" encontrado. Atualizando ID: $idReal');

        DocumentReference propostaRef = FirebaseFirestore.instance
            .collection('coletas')
            .doc(widget.coletaId)
            .collection('propostas')
            .doc(idReal);

        await propostaRef.update({
          'nome': _nomeController.text,
          'cpf': _cpfController.text,
          'placa': _placaController.text,
          'veiculo': _veiculoController.text,
          'timestamp': FieldValue.serverTimestamp(),
          'isShared': true,
        });

        developer.log('Dados atualizados com sucesso no documento $idReal.');

        await FirebaseFirestore.instance
            .collection('coletas')
            .doc(widget.coletaId)
            .update({
          'isShared': true,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados atualizados com sucesso!')),
        );

        DocumentSnapshot coletaAtualizada = await FirebaseFirestore.instance
            .collection('coletas')
            .doc(widget.coletaId)
            .get();

        developer.log(
          'Dados do documento principal (coletaAtualizada): ${coletaAtualizada.data()}',
          name: 'Salvar Coleta',
        );

        if (coletaAtualizada.data() == null) {
          developer.log(
            'Erro: Os dados de coletaAtualizada estão nulos.',
            name: 'Salvar Coleta',
          );
        } else {
          developer.log(
            'Dados válidos em coletaAtualizada: ${coletaAtualizada.data()}',
            name: 'Salvar Coleta',
          );
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CollectProcessRede(
              coletaAtual: coletaAtualizada,
            ),
          ),
        );
      } else {
        developer.log('Nenhuma proposta com status "Aceita" foi encontrada.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Nenhuma proposta com status "Aceita" encontrada.')),
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Erro ao salvar dados na subcoleção "propostas".',
        error: e,
        stackTrace: stackTrace,
        name: 'Salvar Coleta',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar dados: $e')),
      );
    }
  }

  bool _validarCampos() {
    setState(() {
      _nomeError = _nomeController.text.isEmpty ? 'Nome é obrigatório.' : null;
      _cpfError = _validarCPF(_cpfController.text) ? null : 'CPF inválido.';
      _placaError = _placaController.text.isEmpty
          ? 'Placa do veículo é obrigatória.'
          : null;
      _veiculoError = _veiculoController.text.isEmpty
          ? 'Modelo do veículo é obrigatório.'
          : null;
    });

    return _nomeError == null &&
        _cpfError == null &&
        _placaError == null &&
        _veiculoError == null;
  }

  bool _validarCPF(String cpf) {
    final cleanedCpf = cpf.replaceAll(RegExp(r'\D'), '');
    if (cleanedCpf.length != 11) return false;

    final List<int> digits =
        cleanedCpf.split('').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 1; i < digits.length; i++) {
      if (digits[i] != digits[0]) break;
      if (i == digits.length - 1) return false;
    }

    for (int i = 9; i < 11; i++) {
      int sum = 0;
      for (int j = 0; j < i; j++) {
        sum += digits[j] * ((i + 1) - j);
      }
      final digit = (sum * 10) % 11 % 10;
      if (digit != digits[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    developer.log('Construindo interface da tela de detalhes da coleta.');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text(
          'Detalhes da Coleta',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : coleta == null
              ? const Center(
                  child: Text('Detalhes não disponíveis.'),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        _buildDetailsCard(),
                        const Divider(height: 32),
                        const Text(
                          'Preencha os dados abaixo:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _nomeController,
                          label: 'Nome',
                          icon: Icons.person,
                          errorText: _nomeError,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _cpfController,
                          label: 'CPF',
                          icon: Icons.credit_card,
                          keyboardType: TextInputType.number,
                          errorText: _cpfError,
                          inputFormatters: [maskFormatterCPF],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _placaController,
                          label: 'Placa do Veículo',
                          icon: Icons.directions_car,
                          errorText: _placaError,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _veiculoController,
                          label: 'Modelo do Veículo',
                          icon: Icons.directions_car_outlined,
                          errorText: _veiculoError,
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _salvarDadosColeta,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Confirmar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32.0,
                                vertical: 12.0,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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

  Widget _buildDetailsCard() {
    final String region = coleta?['region'] ?? 'Não disponível';
    final String address = coleta?['address'] ?? 'Não disponível';
    final String statusAtual = coleta?['statusAtual'] ?? 'Não disponível';
    final String precoPorLitro =
        coleta?['precoPorLitro']?.toString() ?? 'Não disponível';

    return Center(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 5,
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Informações da Coleta',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Localização: $region',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Endereço: $address',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Status Atual: $statusAtual',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Preço por Litro: $precoPorLitro',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.green),
          borderRadius: BorderRadius.circular(12),
        ),
        errorText: errorText,
      ),
    );
  }
}
