import 'package:flutter/material.dart';

class ColetaInfoCard extends StatelessWidget {
  final String tipoEstabelecimento;
  final String quantidadeOleo;
  final String? endereco;
  final bool mostrarEndereco;

  const ColetaInfoCard({
    super.key,
    required this.tipoEstabelecimento,
    required this.quantidadeOleo,
    this.endereco,
    this.mostrarEndereco = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 5,
        shadowColor: Colors.grey.shade300,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Informações da Coleta',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Tipo de Estabelecimento: $tipoEstabelecimento',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.black87,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Quantidade Estimada: $quantidadeOleo Litros',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.black87,
                    ),
                textAlign: TextAlign.center,
              ),
              if (mostrarEndereco && endereco != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Endereço: $endereco',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.black87,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
