import 'dart:io';

import 'package:ciclou_projeto/screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class UploadDocumentsScreen extends StatefulWidget {
  const UploadDocumentsScreen({super.key});

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  final Map<String, File?> _uploadedFiles = {
    'IBAMA': null,
    'Licença de Operação': null,
    'Alvará de Funcionamento': null,
    'AVCB (Bombeiro)': null,
  };

  Future<void> _pickFile(String documentType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      setState(() {
        _uploadedFiles[documentType] = file;
      });

      await _updateFirestore(documentType, file);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum arquivo selecionado.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateFirestore(String documentType, File file) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuário não autenticado.');
      }

      String firestoreField;
      switch (documentType) {
        case 'IBAMA':
          firestoreField = 'ibama';
          break;
        case 'Licença de Operação':
          firestoreField = 'licenseOperation';
          break;
        case 'Alvará de Funcionamento':
          firestoreField = 'operatingPermit';
          break;
        case 'AVCB (Bombeiro)':
          firestoreField = 'avcb';
          break;
        default:
          throw Exception('Tipo de documento desconhecido.');
      }

      await FirebaseFirestore.instance
          .collection('collector')
          .doc(userId)
          .update({firestoreField: file.path});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Documento atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar documento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitDocuments() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuário não autenticado.');
      }

      final allFiles =
          _uploadedFiles.map((key, value) => MapEntry(key, value?.path));
      debugPrint('Arquivos enviados: $allFiles');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos os documentos foram enviados com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar documentos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Envie os documentos abaixo para poder finalizar o cadastro de coletor:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _uploadedFiles.keys.map((documentType) {
                  final isUploaded = _uploadedFiles[documentType] != null;
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isUploaded ? Colors.green : Colors.red,
                        child: Icon(
                          isUploaded ? Icons.check : Icons.close,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(documentType),
                      subtitle: isUploaded
                          ? Text(
                              'Enviado: ${_uploadedFiles[documentType]?.path.split('/').last}',
                              style: const TextStyle(color: Colors.green),
                            )
                          : const Text(
                              'Pendente',
                              style: TextStyle(color: Colors.red),
                            ),
                      trailing: ElevatedButton(
                        onPressed: () => _pickFile(documentType),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          'Upload',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _uploadedFiles.values.every((file) => file != null)
                    ? _submitDocuments
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Center(
                  child: Text(
                    'Finalizar Envio',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text(
                    'Ir para Login',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}