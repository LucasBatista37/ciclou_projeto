import 'dart:io';
import 'package:ciclou_projeto/components/scaffold_mensager.dart';
import 'package:ciclou_projeto/screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

      await _uploadToFirebase(documentType, file);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum arquivo selecionado.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadToFirebase(String documentType, File file) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuário não autenticado.');
      }

      final fileName =
          'collector_documents/$userId/${documentType.replaceAll(" ", "_")}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);

      final uploadTask = await storageRef.putFile(file);

      final downloadUrl = await uploadTask.ref.getDownloadURL();

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
          .update({firestoreField: downloadUrl});

      ScaffoldMessengerHelper.showSuccess(
        context: context,
        message: 'Documento enviado com sucesso!',
      );
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Erro ao enviar documento.',
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

      ScaffoldMessengerHelper.showSuccess(
        context: context,
        message: 'Todos os documento foram enviado com sucesso!',
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Erro ao enviar documentos.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          'Upload de Documentos',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
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
                          ? const Text(
                              'Enviado',
                              style: TextStyle(color: Colors.green),
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
            ],
          ),
        ),
      ),
    );
  }
}