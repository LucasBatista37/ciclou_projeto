import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _metodoSelecionado = "Pix";
  final _numeroCartaoController = TextEditingController();
  final _nomeTitularController = TextEditingController();
  final _dataValidadeController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _pagamentoConfirmado = false;

  void _confirmarPagamento() {
    setState(() {
      _pagamentoConfirmado = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pagamento realizado com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text(
          'Pagamento',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecione o Método de Pagamento',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              DropdownButtonFormField<String>(
                value: _metodoSelecionado,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: ["Pix", "Cartão de Crédito"].map((metodo) {
                  return DropdownMenuItem(
                    value: metodo,
                    child: Text(metodo),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _metodoSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 16.0),
              if (_metodoSelecionado == "Pix") ...[
                const Text(
                  'Chave Pix',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Text(
                    'Chave Pix: 123.456.789-00',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Após realizar o pagamento, envie o comprovante para o suporte.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ] else if (_metodoSelecionado == "Cartão de Crédito") ...[
                const Text(
                  'Número do Cartão',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                TextField(
                  controller: _numeroCartaoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '1234 5678 9012 3456',
                  ),
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Nome do Titular',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                TextField(
                  controller: _nomeTitularController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Nome como está no cartão',
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Validade',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8.0),
                          TextField(
                            controller: _dataValidadeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'MM/AA',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CVV',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8.0),
                          TextField(
                            controller: _cvvController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: '123',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16.0),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 12.0),
                  ),
                  onPressed: _confirmarPagamento,
                  child: const Text(
                    'Confirmar Pagamento',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              if (_pagamentoConfirmado)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.lightGreen,
                  child: const Text(
                    'Pagamento realizado com sucesso!',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
