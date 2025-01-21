// ignore_for_file: file_names

import 'package:flutter/material.dart';

class ColetaInfoCard extends StatelessWidget {
  final String tipoEstabelecimento;
  final String quantidadeOleo;
  final String? endereco;
  final bool mostrarEndereco;
  final List<String> funcionamentoDias;
  final String funcionamentoHorario;
  final String requestorName;

  const ColetaInfoCard({
    super.key,
    required this.tipoEstabelecimento,
    required this.quantidadeOleo,
    this.endereco,
    this.mostrarEndereco = false,
    required this.funcionamentoDias,
    required this.funcionamentoHorario,
    required this.requestorName,
  });

  String formatFuncionamentoDias(List<String> dias) {
    const diasSemana = [
      "Domingo",
      "Segunda-feira",
      "Terça-feira",
      "Quarta-feira",
      "Quinta-feira",
      "Sexta-feira",
      "Sábado"
    ];

    if (dias.length == 7) return "Todos os dias";
    if (dias.length == 5 &&
        dias.every((dia) => diasSemana.sublist(1, 6).contains(dia))) {
      return "Dias Úteis";
    }
    if (dias.length == 2 &&
        dias.contains("Sábado") &&
        dias.contains("Domingo")) {
      return "Fim de Semana";
    }

    final indices = dias.map((dia) => diasSemana.indexOf(dia)).toList()..sort();
    if (indices.isNotEmpty &&
        indices.last - indices.first + 1 == indices.length) {
      return "${diasSemana[indices.first].substring(0, 3)} à ${diasSemana[indices.last].substring(0, 3)}";
    }

    return dias.map((dia) => dia.substring(0, 3)).join(", ");
  }

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
              const SizedBox(height: 8),
              Text(
                'Responsável: $requestorName',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.black87,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Funcionamento: ${formatFuncionamentoDias(funcionamentoDias)} - $funcionamentoHorario',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.black87,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
