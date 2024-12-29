import 'package:ciclou_projeto/models/user_model.dart';
import 'package:ciclou_projeto/screens/Requestor/requestor_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class CreateCollection extends StatefulWidget {
  final UserModel user;

  const CreateCollection({super.key, required this.user});

  @override
  // ignore: library_private_types_in_public_api
  _CreateCollectionState createState() => _CreateCollectionState();
}

class _CreateCollectionState extends State<CreateCollection> {
  final _formKey = GlobalKey<FormState>();
  double? _quantidadeOleo;
  final _comentariosController = TextEditingController();
  final _chavePixController = TextEditingController();
  String? _formaRecebimento;
  final _bancoController = TextEditingController();
  final _regionController = TextEditingController();
  bool _isLoading = false;
  List<String> _bancos = [];

  final List<String> _diasFuncionamento = [];
  final _horarioFuncionamentoController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();
  final List<String> _diasDaSemana = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo'
  ];

  @override
  void initState() {
    super.initState();
    _carregarBancos();
    _enderecoController.text = widget.user.address;
    _preencherRegiao();
  }

  @override
  void dispose() {
    _enderecoController.dispose();
    super.dispose();
  }

  Future<void> _carregarBancos() async {
    try {
      final csvData = await rootBundle.loadString('assets/banco.csv');
      final List<List<dynamic>> csvTable =
          const CsvToListConverter().convert(csvData, eol: '\n');

      setState(() {
        _bancos = csvTable
            .skip(1)
            .map((row) => row[3]?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar bancos: $e')),
      );
    }
  }

  String? _validarChavePix(String? value) {
    if (_formaRecebimento == null) return 'Selecione a forma de recebimento';
    if (_formaRecebimento == 'CPF' && (value == null || value.length != 11)) {
      return 'Digite um CPF válido com 11 dígitos';
    } else if (_formaRecebimento == 'CNPJ' &&
        (value == null || value.length != 14)) {
      return 'Digite um CNPJ válido com 14 dígitos';
    } else if (_formaRecebimento == 'E-mail' &&
        (value == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))) {
      return 'Digite um e-mail válido';
    } else if (_formaRecebimento == 'Chave Aleatória' &&
        (value == null || value.isEmpty)) {
      return 'Digite uma chave válida';
    }
    return null;
  }

  Future<void> _enviarSolicitacao() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userId = widget.user.userId;

        if (userId != null) {
          await FirebaseFirestore.instance
              .collection('requestor')
              .doc(userId)
              .update({
            'address': _enderecoController.text.trim(),
          });
        }

        await FirebaseFirestore.instance.collection('coletas').add({
          'tipoEstabelecimento': widget.user.establishmentType,
          'quantidadeOleo': _quantidadeOleo,
          'prazo':
              DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
          'comentarios': _comentariosController.text.trim(),
          'tipoChavePix': _formaRecebimento,
          'chavePix': _chavePixController.text.trim(),
          'banco': _bancoController.text.trim(),
          'address': _enderecoController.text.trim(),   
          'region': _regionController.text.trim(),
          'status': 'Pendente',
          'userId': widget.user.userId,
          'requestorName': widget.user.responsible,
          'createdAt': FieldValue.serverTimestamp(),
          'funcionamentoDias': _diasFuncionamento,
          'funcionamentoHorario': _horarioFuncionamentoController.text.trim(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitação enviada com sucesso!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RequestorDashboard(user: widget.user),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar solicitação: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos obrigatórios.')),
      );
    }
  }

  Widget _buildDiasFuncionamentoSelector() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: _diasDaSemana.map((dia) {
        final isSelected = _diasFuncionamento.contains(dia);
        return ChoiceChip(
          label: Text(dia),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _diasFuncionamento.add(dia);
              } else {
                _diasFuncionamento.remove(dia);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Future<void> _preencherRegiao() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          throw Exception('Permissão de localização negada');
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String cidade = placemark.locality?.isNotEmpty == true
            ? placemark.locality!
            : placemark.subAdministrativeArea ?? 'Cidade desconhecida';
        String estado = placemark.administrativeArea ?? 'Estado desconhecido';
        String bairro = placemark.subLocality ?? 'Bairro desconhecido';

        String regiao = '$bairro, $cidade, $estado';

        setState(() {
          _regionController.text = regiao;
        });
      } else {
        throw Exception('Nenhum placemark encontrado.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao obter localização: $e')),
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
          'Criar Solicitação',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Entre em contato com o suporte para ajuda!')),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipo de Estabelecimento',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      widget.user.establishmentType ?? 'Tipo não definido',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Endereço',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _enderecoController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Digite o endereço',
                      ),
                      onChanged: (value) {
                        widget.user.address = value;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Quantidade Estimada de Óleo (em litros)',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Digite a quantidade em litros',
                      ),
                      onChanged: (value) {
                        _quantidadeOleo = double.tryParse(value);
                      },
                      validator: (value) {
                        if (value == null || double.tryParse(value) == null) {
                          return 'Digite uma quantidade válida';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pagamento',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          const Text(
                            'Forma de recebimento',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8.0),
                          DropdownButtonFormField<String>(
                            value: _formaRecebimento,
                            items: [
                              'CPF',
                              'CNPJ',
                              'E-mail',
                              'Chave Aleatória',
                            ]
                                .map((tipo) => DropdownMenuItem(
                                      value: tipo,
                                      child: Text(tipo),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _formaRecebimento = value;
                                _chavePixController.clear();
                                _bancoController.clear();
                              });
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Selecione a forma de recebimento',
                            ),
                            validator: (value) => value == null
                                ? 'Selecione a forma de recebimento'
                                : null,
                          ),
                          const SizedBox(height: 16.0),
                          const Text(
                            'Chave Pix',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8.0),
                          TextFormField(
                            controller: _chavePixController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: _formaRecebimento == null
                                  ? 'Digite a chave Pix'
                                  : 'Digite sua $_formaRecebimento',
                            ),
                            keyboardType: _formaRecebimento == 'CPF' ||
                                    _formaRecebimento == 'CNPJ'
                                ? TextInputType.number
                                : TextInputType.text,
                            validator: _validarChavePix,
                          ),
                          const SizedBox(height: 16.0),
                          const Text(
                            'Banco',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8.0),
                          Autocomplete<String>(
                            optionsBuilder:
                                (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return const Iterable<String>.empty();
                              }
                              return _bancos.where((banco) => banco
                                  .toLowerCase()
                                  .contains(
                                      textEditingValue.text.toLowerCase()));
                            },
                            onSelected: (String selection) {
                              _bancoController.text = selection;
                            },
                            fieldViewBuilder: (BuildContext context,
                                TextEditingController fieldController,
                                FocusNode focusNode,
                                VoidCallback onFieldSubmitted) {
                              _bancoController.text = fieldController.text;
                              return TextFormField(
                                controller: fieldController,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Digite ou selecione o banco',
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16.0),
                          Container(
                            color: Colors.green.shade50,
                            padding: const EdgeInsets.all(8.0),
                            child: const Text(
                              'Por favor, revise cuidadosamente todas as informações aqui preenchidas.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Prazo para Recebimento de Propostas',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    const Text(
                      '15 minutos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Região',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _regionController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Região (Estado, Cidade, Bairro)',
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Dias de Funcionamento',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    _buildDiasFuncionamentoSelector(),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Horário de Funcionamento',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _horarioFuncionamentoController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Exemplo: 08:00 - 18:00',
                      ),
                      keyboardType: TextInputType.datetime,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe o horário de funcionamento';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Comentários ou Informações Adicionais',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _comentariosController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText:
                            'Adicione comentários ou informações adicionais',
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Center(
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0, vertical: 12.0),
                              ),
                              onPressed: _enviarSolicitacao,
                              child: const Text('Enviar Solicitação',
                                  style: TextStyle(color: Colors.white)),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}