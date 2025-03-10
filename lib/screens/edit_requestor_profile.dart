import 'dart:io';
import 'package:ciclou_projeto/components/scaffold_mensager.dart';
import 'package:ciclou_projeto/utils/colors.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class EditRequestorProfile extends StatefulWidget {
  const EditRequestorProfile({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EditRequestorProfileState createState() => _EditRequestorProfileState();
}

class _EditRequestorProfileState extends State<EditRequestorProfile> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _establishmentTypeController =
      TextEditingController();
  XFile? _profileImage;
  bool _isLoading = false;
  String? _profileUrl;

  final _telefoneMaskFormatter =
      MaskTextInputFormatter(mask: "(##) #####-####");
  final _cnpjMaskFormatter = MaskTextInputFormatter(mask: "##.###.###/####-##");

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _businessNameController.dispose();
    _cnpjController.dispose();
    _establishmentTypeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('requestor')
            .doc(uid)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _nomeController.text = data['responsible'] ?? '';
            _telefoneController.text = data['phone'] ?? '';
            _enderecoController.text = data['address'] ?? '';
            _businessNameController.text = data['businessName'] ?? '';
            _cnpjController.text = data['cnpj'] ?? '';
            _establishmentTypeController.text = data['establishmentType'] ?? '';
            _profileUrl = data['photoUrl'];
          });
        }
      } catch (e) {
        ScaffoldMessengerHelper.showError(
          // ignore: use_build_context_synchronously
          context: context,
          message: 'Erro ao carregar dados',
        );
      }
    }
  }

  Future<void> _updatePhotoUrl(String photoPath) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('requestor_photos')
            .child('$uid.jpg');

        final uploadTask = await storageRef.putFile(File(photoPath));
        final photoUrl = await uploadTask.ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('requestor')
            .doc(uid)
            .update({
          'photoUrl': photoUrl,
        });

        ScaffoldMessengerHelper.showSuccess(
          // ignore: use_build_context_synchronously
          context: context,
          message: 'Foto de perfil atualizada com sucesso!',
        );
      } catch (e) {
        ScaffoldMessengerHelper.showError(
          // ignore: use_build_context_synchronously
          context: context,
          message: 'Erro ao atualizar foto.',
        );
      }
    } else {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Usuário não autenticado.',
      );
    }
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Usuário não autenticado.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('requestor').doc(uid).update({
        'responsible': _nomeController.text.trim(),
        'phone': _telefoneController.text.trim(),
        'address': _enderecoController.text.trim(),
        'businessName': _businessNameController.text.trim(),
        'cnpj': _cnpjController.text.trim(),
        'establishmentType': _establishmentTypeController.text.trim(),
        'photoUrl': _profileImage != null
            ? await _uploadImage(File(_profileImage!.path))
            : null,
      });

      ScaffoldMessengerHelper.showSuccess(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Dados salvos com sucesso!',
      );
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Erro ao salvar dados.',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _uploadImage(File imageFile) async {
    try {
      final fileName =
          'requestor_photos/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = await storageRef.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Erro ao fazer upload da imagem: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      final file = File(pickedImage.path);
      final fileSizeInMB = file.lengthSync() / (1024 * 1024);

      if (fileSizeInMB > 2) {
        ScaffoldMessengerHelper.showWarning(
          // ignore: use_build_context_synchronously
          context: context,
          message:
              'O arquivo selecionado é muito grande. O tamanho máximo permitido é 2MB.',
        );
        return;
      }

      setState(() {
        _profileImage = pickedImage;
      });

      await _updatePhotoUrl(pickedImage.path);
    } else {
      ScaffoldMessengerHelper.showWarning(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Nenhuma imagem selecionada.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.green1,
        centerTitle: true,
        title: const Text(
          'Editar Perfil',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: _profileImage != null
                              ? FileImage(File(_profileImage!.path))
                              : (_profileUrl != null
                                  ? NetworkImage(_profileUrl!)
                                  : null),
                          child: (_profileImage == null && _profileUrl == null)
                              ? Text(
                                  _nomeController.text.isNotEmpty
                                      ? _nomeController.text[0].toUpperCase()
                                      : '',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.black,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: const CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.green,
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    label: 'Nome',
                    controller: _nomeController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'O nome é obrigatório';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Telefone',
                    controller: _telefoneController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'O telefone é obrigatório';
                      }
                      return null;
                    },
                    inputFormatters: [_telefoneMaskFormatter],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Endereço',
                    controller: _enderecoController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'O endereço é obrigatório';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Razão Social',
                    controller: _businessNameController,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'CNPJ',
                    controller: _cnpjController,
                    inputFormatters: [_cnpjMaskFormatter],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Tipo de Estabelecimento',
                    controller: _establishmentTypeController,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveUserData,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: const Text(
                      'Salvar Alterações',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
      inputFormatters: inputFormatters,
    );
  }
}
