import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'custom_text_field.dart';
import 'custom_dropdown_field.dart';

class CollectDataForm extends StatelessWidget {
  final TextEditingController nomeController;
  final TextEditingController cpfController;
  final TextEditingController placaController;
  final TextEditingController veiculoController;
  final String? selectedVehicleType;
  final List<String> vehicleTypes;
  final ValueChanged<String?> onVehicleTypeChanged;

  final String? nomeError;
  final String? cpfError;
  final String? placaError;
  final String? veiculoError;

  final MaskTextInputFormatter cpfMaskFormatter;

  const CollectDataForm({
    super.key,
    required this.nomeController,
    required this.cpfController,
    required this.placaController,
    required this.veiculoController,
    required this.selectedVehicleType,
    required this.vehicleTypes,
    required this.onVehicleTypeChanged,
    this.nomeError,
    this.cpfError,
    this.placaError,
    this.veiculoError,
    required this.cpfMaskFormatter,
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
        const SizedBox(height: 16),
        CustomDropdownField(
          label: 'Tipo de Veículo',
          icon: Icons.local_shipping,
          value: selectedVehicleType,
          items: vehicleTypes,
          onChanged: onVehicleTypeChanged,
        ),
      ],
    );
  }
}