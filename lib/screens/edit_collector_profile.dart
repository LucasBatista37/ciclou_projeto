import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class EditCollectorProfile extends StatefulWidget {
  const EditCollectorProfile({super.key});

  @override
  _EditCollectorProfileState createState() => _EditCollectorProfileState();
}

class _EditCollectorProfileState extends State<EditCollectorProfile> {
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _responsibleController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _licenseNumberController =
      TextEditingController();
  final TextEditingController _licenseExpiryController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  XFile? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('collector')
          .doc(uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _businessNameController.text = data['businessName'] ?? '';
          _cnpjController.text = data['cnpj'] ?? '';
          _addressController.text = data['address'] ?? '';
          _responsibleController.text = data['responsible'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _licenseNumberController.text = data['licenseNumber'] ?? '';
          _licenseExpiryController.text = data['licenseExpiry'] ?? '';
          _emailController.text = data['email'] ?? '';
        });
      }
    }
  }

  Future<void> _saveUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('collector')
            .doc(uid)
            .update({
          'businessName': _businessNameController.text.trim(),
          'cnpj': _cnpjController.text.trim(),
          'address': _addressController.text.trim(),
          'responsible': _responsibleController.text.trim(),
          'phone': _phoneController.text.trim(),
          'licenseNumber': _licenseNumberController.text.trim(),
          'licenseExpiry': _licenseExpiryController.text.trim(),
          'email': _emailController.text.trim(),
          'photoUrl': _profileImage != null ? _profileImage!.path : null,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados salvos com sucesso!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar os dados: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado.')),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _profileImage = pickedImage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                children: [
                  _profileImage == null
                      ? CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade300,
                          child: Text(
                            _responsibleController.text.isNotEmpty
                                ? _responsibleController.text[0].toUpperCase()
                                : '',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                        )
                      : CircleAvatar(
                          radius: 50,
                          backgroundImage: FileImage(File(_profileImage!.path)),
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
                label: 'Responsável', controller: _responsibleController),
            const SizedBox(height: 16),
            _buildTextField(label: 'Email', controller: _emailController),
            const SizedBox(height: 16),
            _buildTextField(label: 'Telefone', controller: _phoneController),
            const SizedBox(height: 16),
            _buildTextField(label: 'Endereço', controller: _addressController),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
