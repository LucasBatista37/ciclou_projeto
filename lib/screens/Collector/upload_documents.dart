import 'dart:io';
import 'package:ciclou_projeto/components/scaffold_mensager.dart';
import 'package:ciclou_projeto/models/user_model.dart';
import 'package:ciclou_projeto/screens/Collector/view_documents_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UploadDocumentsScreen extends StatefulWidget {
  final UserModel user;

  const UploadDocumentsScreen({super.key, required this.user});

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

  final Map<String, bool> _isUploaded = {
    'IBAMA': false,
    'Licença de Operação': false,
    'Alvará de Funcionamento': false,
    'AVCB (Bombeiro)': false,
  };

  final Map<String, String?> _documentUrls = {
    'IBAMA': null,
    'Licença de Operação': null,
    'Alvará de Funcionamento': null,
    'AVCB (Bombeiro)': null,
  };

  @override
  void initState() {
    super.initState();
    _fetchUploadedDocuments();
  }

  Future<void> _fetchUploadedDocuments() async {
    try {
      final userId = widget.user.userId;
      final docSnapshot = await FirebaseFirestore.instance
          .collection('collector')
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        setState(() {
          _isUploaded['IBAMA'] = data['ibama'] != null;
          _documentUrls['IBAMA'] = data['ibama'];

          _isUploaded['Licença de Operação'] = data['licenseOperation'] != null;
          _documentUrls['Licença de Operação'] = data['licenseOperation'];

          _isUploaded['Alvará de Funcionamento'] =
              data['operatingPermit'] != null;
          _documentUrls['Alvará de Funcionamento'] = data['operatingPermit'];

          _isUploaded['AVCB (Bombeiro)'] = data['avcb'] != null;
          _documentUrls['AVCB (Bombeiro)'] = data['avcb'];
        });
      }
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Erro ao carregar documentos enviados.',
      );
    }
  }

  Future<void> _pickFile(String documentType) async {
    // Verifica se o documento já foi enviado
    if (_isUploaded[documentType] ?? false) {
      ScaffoldMessengerHelper.showWarning(
        context: context,
        message: 'Você já enviou o documento "$documentType".',
      );
      return;
    }

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
      // ignore: use_build_context_synchronously
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
      final userId = widget.user.userId;

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

      setState(() {
        _isUploaded[documentType] = true;
        _documentUrls[documentType] = downloadUrl;
      });

      ScaffoldMessengerHelper.showSuccess(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Documento enviado com sucesso!',
      );
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Erro ao enviar documento.',
      );
    }
  }

  Future<void> _viewDocument(
      BuildContext context, String documentUrl, String documentType) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewerScreen(
          documentUrl: documentUrl,
          documentType: documentType,
        ),
      ),
    );
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
                  final isUploaded = _isUploaded[documentType] ?? false;
                  final documentUrl = _documentUrls[documentType];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    isUploaded ? Colors.green : Colors.red,
                                child: Icon(
                                  isUploaded ? Icons.check : Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                documentType,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _pickFile(documentType),
                                  icon: const Icon(
                                    Icons.upload_file,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Upload',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (isUploaded && documentUrl != null)
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _viewDocument(
                                        context, documentUrl, documentType),
                                    icon: const Icon(
                                      Icons.visibility,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Visualizar',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}