import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ComprovanteOverlay extends StatefulWidget {
  final Function(File?) onComprovanteSelecionado;
  final VoidCallback onEnviarComprovante;

  const ComprovanteOverlay({
    super.key,
    required this.onComprovanteSelecionado,
    required this.onEnviarComprovante,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ComprovanteOverlayState createState() => _ComprovanteOverlayState();
}

class _ComprovanteOverlayState extends State<ComprovanteOverlay> {
  File? _comprovanteSelecionado;

  Future<void> _selecionarComprovante() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _comprovanteSelecionado = File(result.files.single.path!);
      });

      widget.onComprovanteSelecionado(_comprovanteSelecionado);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comprovante selecionado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      title: const Text(
        'Enviar Comprovante de Pagamento',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_comprovanteSelecionado != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comprovante Selecionado:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    _comprovanteSelecionado!.path.split('/').last,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ElevatedButton.icon(
            onPressed: _selecionarComprovante,
            icon: const Icon(Icons.upload, color: Colors.white),
            label: const Text(
              'Selecionar Comprovante',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(
                  vertical: 12.0, horizontal: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'Cancelar',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _comprovanteSelecionado != null
              ? widget.onEnviarComprovante
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(
                vertical: 12.0, horizontal: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: const Text(
            'Enviar e Finalizar',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}