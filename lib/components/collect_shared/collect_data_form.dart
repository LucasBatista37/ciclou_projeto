import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'custom_text_field.dart';

class CollectDataForm extends StatelessWidget {
  final TextEditingController nomeController;
  final TextEditingController cpfController;
  final TextEditingController placaController;
  final TextEditingController veiculoController;
  final TextEditingController rgController;

  final String? nomeError;
  final String? cpfError;
  final String? placaError;
  final String? veiculoError;
  final String? rgError;

  final MaskTextInputFormatter cpfMaskFormatter;
  final MaskTextInputFormatter rgMaskFormatter;

  const CollectDataForm({
    super.key,
    required this.nomeController,
    required this.cpfController,
    required this.placaController,
    required this.veiculoController,
    required this.rgController,
    required this.cpfMaskFormatter,
    required this.rgMaskFormatter,
    this.nomeError,
    this.cpfError,
    this.placaError,
    this.veiculoError,
    this.rgError,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Insira as informações abaixo:',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        CustomTextField(
          controller: nomeController,
          label: 'Nome',
          icon: Icons.person,
          errorText: nomeError,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: cpfController,
          label: 'CPF',
          icon: Icons.credit_card,
          keyboardType: TextInputType.number,
          errorText: cpfError,
          inputFormatters: [cpfMaskFormatter],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: rgController,
          label: 'RG',
          icon: Icons.badge,
          keyboardType: TextInputType.number,
          errorText: rgError,
          inputFormatters: [rgMaskFormatter],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: placaController,
          label: 'Placa do Veículo',
          icon: Icons.directions_car,
          errorText: placaError,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: veiculoController,
          label: 'Modelo do Veículo',
          icon: Icons.directions_car_outlined,
          errorText: veiculoError,
        ),
      ],
    );
  }
}
