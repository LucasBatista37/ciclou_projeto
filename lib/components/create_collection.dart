import 'package:flutter/material.dart';

class PagamentoForm extends StatelessWidget {
  final String? formaRecebimento;
  final Function(String?) onFormaRecebimentoChanged;
  final TextEditingController chavePixController;
  final TextEditingController bancoController;
  final Function(String?) validarChavePix;
  final Future<List<String>> Function() carregarBancos;

  const PagamentoForm({
    Key? key,
    required this.formaRecebimento,
    required this.onFormaRecebimentoChanged,
    required this.chavePixController,
    required this.bancoController,
    required this.validarChavePix,
    required this.carregarBancos,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Future<List<String>> bancosFuture = carregarBancos();

    return Container(
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          DropdownButtonFormField<String>(
            value: formaRecebimento,
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
            onChanged: onFormaRecebimentoChanged,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Selecione a forma de recebimento',
            ),
            validator: (value) =>
                value == null ? 'Selecione a forma de recebimento' : null,
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Chave Pix',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: chavePixController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: formaRecebimento == null
                  ? 'Digite a chave Pix'
                  : 'Digite sua $formaRecebimento',
            ),
            keyboardType:
                formaRecebimento == 'CPF' || formaRecebimento == 'CNPJ'
                    ? TextInputType.number
                    : TextInputType.text,
            validator: (value) => validarChavePix(value),
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Banco',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          FutureBuilder<List<String>>(
            future: bancosFuture, 
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return const Text('Erro ao carregar os bancos');
              } else {
                final bancos = snapshot.data ?? [];
                return Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return bancos.where((banco) => banco
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (String selection) {
                    bancoController.text = selection;
                  },
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController fieldController,
                      FocusNode focusNode,
                      VoidCallback onFieldSubmitted) {
                    bancoController.text = fieldController.text;
                    return TextFormField(
                      controller: fieldController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Digite ou selecione o banco',
                      ),
                    );
                  },
                );
              }
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
    );
  }
}
