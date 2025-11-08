// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String? selectedGender;
  final List<String> genderOptions = ['Feminino', 'Masculino', 'Prefiro não comentar'];
  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isEditing = false;
  File? _selectedImage;
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();
  
  // Controladores para edição
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    try {
      _currentUser = FirebaseAuth.instance.currentUser;
      
      if (_currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .get();
        
        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data()!;
            selectedGender = _userData!['gender'];
            _nameController.text = _userData!['name'] ?? '';
            _ageController.text = _userData!['age']?.toString() ?? '';
            _phoneController.text = _userData!['phone'] ?? '';
            _imageUrl = _userData!['photoUrl'];
          });
        } else {
          _nameController.text = _currentUser!.email!.split('@')[0];
        }
      }
    } catch (e) {
      print('Erro ao carregar dados: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 500,
        maxHeight: 500,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        
        // Upload automático quando seleciona a imagem
        await _uploadImage();
      }
    } catch (e) {
      print('Erro ao selecionar imagem: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar imagem: $e')),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null || _currentUser == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Referência do Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profile_images')
          .child('${_currentUser!.uid}.jpg');

      // Faz upload da imagem
      await storageRef.putFile(_selectedImage!);
      
      // Pega a URL da imagem
      final downloadUrl = await storageRef.getDownloadURL();

      // Salva a URL no Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .set({
            'photoUrl': downloadUrl,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      setState(() {
        _imageUrl = downloadUrl;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Foto atualizada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer upload: $e')),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Escolher da Galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Tirar Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_imageUrl != null || _selectedImage != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Remover Foto', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _removePhoto();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _removePhoto() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Remove do Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .set({
            'photoUrl': FieldValue.delete(),
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Remove do Storage (opcional)
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_profile_images')
            .child('${_currentUser!.uid}.jpg');
        await storageRef.delete();
      } catch (e) {
        print('Imagem não encontrada no storage: $e');
      }

      setState(() {
        _imageUrl = null;
        _selectedImage = null;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Foto removida com sucesso!')),
      );

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover foto: $e')),
      );
    }
  }

  void _saveUserData() async {
    if (_currentUser == null) return;

    try {
      setState(() {
        _isLoading = true;
        _isEditing = false;
      });

      final userData = {
        'name': _nameController.text.trim(),
        'email': _currentUser!.email,
        'gender': selectedGender,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (_ageController.text.trim().isNotEmpty) {
        userData['age'] = int.tryParse(_ageController.text.trim()) ?? 0;
      }

      if (_phoneController.text.trim().isNotEmpty) {
        userData['phone'] = _phoneController.text.trim();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .set(userData, SetOptions(merge: true));

      setState(() {
        _userData = userData;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dados atualizados com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showGenderOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: genderOptions.map((String gender) {
            return ListTile(
              leading: selectedGender == gender 
                  ? Icon(Icons.check, color: Colors.green)
                  : null,
              title: Text(gender),
              onTap: () {
                setState(() {
                  selectedGender = gender;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      print('Erro no logout: $e');
    }
  }

  String _getDisplayName() {
    return _nameController.text.isNotEmpty 
        ? _nameController.text 
        : _userData?['name'] ?? _currentUser?.email?.split('@')[0] ?? 'Usuário';
  }

  String _getUserInitials() {
    final name = _getDisplayName();
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name[0].toUpperCase();
  }

  Widget _buildEditableField(String label, TextEditingController controller, String hintText, TextInputType keyboardType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: _isEditing,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: _isEditing ? Colors.white : Colors.grey[100],
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Minha Conta')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Minha Conta'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _loadUserData();
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar com opção de edição
              Stack(
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.green,
                    backgroundImage: _imageUrl != null
                        ? NetworkImage(_imageUrl!) as ImageProvider
                        : _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : null,
                    child: _imageUrl == null && _selectedImage == null
                        ? Text(
                            _getUserInitials(),
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          onPressed: _showImagePickerOptions,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 30),

              // Campos editáveis
              _buildEditableField(
                'Nome Completo',
                _nameController,
                'Digite seu nome',
                TextInputType.text,
              ),

              _buildEditableField(
                'Idade',
                _ageController,
                'Digite sua idade',
                TextInputType.number,
              ),

              _buildEditableField(
                'Telefone',
                _phoneController,
                'Digite seu telefone',
                TextInputType.phone,
              ),

              // Gênero
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gênero',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _isEditing ? _showGenderOptions : null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      side: BorderSide(color: _isEditing ? Colors.grey : Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedGender ?? "Selecione seu gênero",
                          style: TextStyle(
                            color: selectedGender != null ? Colors.black : Colors.grey,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: _isEditing ? Colors.grey : Colors.grey[300]),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),

              // Email (não editável)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      _currentUser?.email ?? 'Email não disponível',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),

              // Botões de ação
              if (_isEditing)
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _saveUserData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text('Salvar Alterações', style: TextStyle(color: Colors.white)),
                    ),
                    SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          _loadUserData();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text('Cancelar'),
                    ),
                    SizedBox(height: 20),
                  ],
                ),

              if (!_isEditing)
                ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text('Sair da Conta', style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}