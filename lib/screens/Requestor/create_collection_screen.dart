import 'package:ciclou_projeto/models/user_model.dart';
import 'package:ciclou_projeto/screens/Requestor/requestor_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreateCollection extends StatefulWidget {
  final UserModel user;

  const CreateCollection({super.key, required this.user});

  @override
  _CreateCollectionState createState() => _CreateCollectionState();
}

class _CreateCollectionState extends State<CreateCollection> {
  final _formKey = GlobalKey<FormState>();
  double? _quantidadeOleo;
  final _comentariosController = TextEditingController();
  final _chavePixController = TextEditingController();
  String? _tipoChavePix;
  final _bancoController = TextEditingController();
  bool _isLoading = false;
  List<String> _bancos = [];

  @override
  void initState() {
    super.initState();
    _carregarBancos();
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

      print("Bancos carregados: $_bancos");
    } catch (e) {
      print("Erro ao carregar bancos: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar bancos: $e')),
      );
    }
  }

  String? _validarChavePix(String? value) {
    if (_tipoChavePix == null) return 'Selecione o tipo de chave Pix';
    if (_tipoChavePix == 'CPF' && (value == null || value.length != 11)) {
      return 'Digite um CPF válido com 11 dígitos';
    } else if (_tipoChavePix == 'CNPJ' &&
        (value == null || value.length != 14)) {
      return 'Digite um CNPJ válido com 14 dígitos';
    } else if (_tipoChavePix == 'E-mail' &&
        (value == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))) {
      return 'Digite um e-mail válido';
    } else if (_tipoChavePix == 'Chave Aleatória' &&
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
        await FirebaseFirestore.instance.collection('coletas').add({
          'tipoEstabelecimento': widget.user.establishmentType,
          'quantidadeOleo': _quantidadeOleo,
          'prazo':
              DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
          'comentarios': _comentariosController.text.trim(),
          'tipoChavePix': _tipoChavePix,
          'chavePix': _chavePixController.text.trim(),
          'banco': _bancoController.text.trim(),
          'address': widget.user.address,
          'status': 'Pendente',
          'userId': widget.user.userId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitação enviada com sucesso!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => RequestorDashboard(user: widget.user)),
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
                    Text(
                      widget.user.address ?? 'Endereço não informado',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
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
                    const Text(
                      'Tipo de Chave Pix',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    DropdownButtonFormField<String>(
                      value: _tipoChavePix,
                      items: ['CPF', 'CNPJ', 'E-mail', 'Chave Aleatória']
                          .map((tipo) => DropdownMenuItem(
                                value: tipo,
                                child: Text(tipo),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _tipoChavePix = value;
                          _chavePixController.clear();
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Selecione o tipo de chave Pix',
                      ),
                      validator: (value) => value == null
                          ? 'Selecione o tipo de chave Pix'
                          : null,
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Chave Pix',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _chavePixController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: _tipoChavePix == null
                            ? 'Digite a chave Pix'
                            : 'Digite sua $_tipoChavePix',
                      ),
                      keyboardType:
                          _tipoChavePix == 'CPF' || _tipoChavePix == 'CNPJ'
                              ? TextInputType.number
                              : TextInputType.text,
                      validator: _validarChavePix,
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Banco',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        return _bancos.where((banco) => banco
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()));
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
