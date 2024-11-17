import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class CreateCollection extends StatefulWidget {
  const CreateCollection({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CreateCollectionState createState() => _CreateCollectionState();
}

class _CreateCollectionState extends State<CreateCollection> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedTipoEstabelecimento;
  double? _quantidadeOleo;
  DateTime? _prazo;
  final _comentariosController = TextEditingController();
  LatLng _localizacaoSelecionada = LatLng(-24.0924, -46.6213);
  late GoogleMapController _mapController;

  final List<String> _tiposEstabelecimento = [
    'Restaurante',
    'Residência',
    'Escola',
    'Condomínio',
    'Associação'
  ];

  @override
  void initState() {
    super.initState();
    _verificarPermissoes();
  }

  Future<void> _verificarPermissoes() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      await Permission.location.request();
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
            onPressed: () {},
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics:
                const ClampingScrollPhysics(), 
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
                    DropdownButtonFormField<String>(
                      value: _selectedTipoEstabelecimento,
                      hint: const Text('Selecione o tipo'),
                      items: _tiposEstabelecimento.map((tipo) {
                        return DropdownMenuItem(
                          value: tipo,
                          child: Text(tipo),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTipoEstabelecimento = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Campo obrigatório' : null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
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
                      'Prazo para Recebimento de Propostas',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    InkWell(
                      onTap: _selecionarData,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Selecione uma data',
                        ),
                        child: Text(
                          _prazo != null
                              ? _prazo.toString().split(' ')[0]
                              : 'Selecione uma data',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Localização',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _localizacaoSelecionada,
                          zoom: 15,
                        ),
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                        onTap: _selecionarLocalizacao,
                        markers: {
                          Marker(
                            markerId: const MarkerId('localSelecionado'),
                            position: _localizacaoSelecionada,
                          ),
                        },
                        gestureRecognizers: Set()
                          ..add(Factory<PanGestureRecognizer>(
                              () => PanGestureRecognizer())),
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
                      child: ElevatedButton(
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

  Future<void> _selecionarData() async {
    DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (dataSelecionada != null) {
      setState(() {
        _prazo = dataSelecionada;
      });
    }
  }

  void _selecionarLocalizacao(LatLng localizacao) {
    setState(() {
      _localizacaoSelecionada = localizacao;
      _mapController.animateCamera(
        CameraUpdate.newLatLng(localizacao),
      );
    });
  }

  void _enviarSolicitacao() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitação enviada com sucesso!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos obrigatórios.')),
      );
    }
  }
}
