import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfilPage extends StatefulWidget {
  final String userId;
  final String initialName;
  final String initialPhone;
  final String initialEmail;
  final String? initialPassword;
  final String initialFoto;

  const EditProfilPage({
    super.key,
    required this.userId,
    required this.initialName,
    required this.initialPhone,
    required this.initialEmail,
    required this.initialFoto,
    this.initialPassword,
  });

  @override
  State<EditProfilPage> createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  late FocusNode _passwordFocusNode;
  bool _showConfirmPassword = false;
  late String _initialPasswordValue;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _emailController = TextEditingController(text: widget.initialEmail);
    _passwordController = TextEditingController(text: '');

    _confirmPasswordController = TextEditingController();
    _passwordFocusNode = FocusNode();

    _initialPasswordValue = _passwordController.text;
    _passwordController.addListener(_handlePasswordChange);
  }

  void _handlePasswordChange() {
    final current = _passwordController.text.trim();
    final changed = current != _initialPasswordValue.trim();

    if (changed != _showConfirmPassword) {
      setState(() {
        _showConfirmPassword = changed;
      });
    }
  }

  @override
  void dispose() {
    _passwordController.removeListener(_handlePasswordChange);
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Ambil dari Kamera'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _editField({
    required String label,
    required TextEditingController controller,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? toggleObscure,
    FocusNode? focusNode,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              obscureText: isPassword ? obscure : false,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon:
                    isPassword
                        ? IconButton(
                          icon: Icon(
                            obscure ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: toggleObscure,
                        )
                        : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitProfile() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final passwordChanged = password != _initialPasswordValue.trim();

    if (passwordChanged) {
      if (password.isEmpty || confirmPassword.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mohon isi password dan konfirmasi password'),
          ),
        );
        return;
      }
      if (password != confirmPassword) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Password tidak sama')));
        return;
      }
    }

    // 👉 Konversi gambar ke base64 jika ada
    String? base64Image;
    if (_imageFile != null) {
      final bytes = await _imageFile!.readAsBytes();
      base64Image = base64Encode(bytes);
    }

    final client = GraphQLProvider.of(context).value;

    const String mutation = r'''
    mutation UpdateUser($id: ID!, $nama: String, $no_hp: String, $email: String, $password: String, $foto: String) {
      updateUser(
        id: $id,
        nama: $nama,
        no_hp: $no_hp,
        email: $email,
        password: $password,
        foto: $foto
      ) {
        id
        nama
        no_hp
        email
        foto
      }
    }
  ''';

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          'id': widget.userId,
          'nama': _nameController.text,
          'no_hp': _phoneController.text,
          'email': _emailController.text,
          'password': passwordChanged ? password : null,
          'foto': base64Image,
        },
      ),
    );

    if (result.hasException) {
      debugPrint(result.exception.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal update profil')));
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nama', _nameController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 34, 102, 141),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Edit Profil'),
        backgroundColor: const Color.fromARGB(255, 34, 102, 141),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundImage:
                      _imageFile != null
                          ? FileImage(_imageFile!)
                          : (widget.initialFoto.isNotEmpty
                                  ? MemoryImage(
                                    base64Decode(widget.initialFoto),
                                  )
                                  : const AssetImage(
                                    'assets/images/profile.jpg',
                                  ))
                              as ImageProvider,
                ),

                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.black),
                        onPressed: _showImageSourceDialog,
                        tooltip: 'Ganti Foto Profil',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _editField(label: 'Nama', controller: _nameController),
            _editField(label: 'No. HP', controller: _phoneController),
            _editField(label: 'E-mail', controller: _emailController),
            _editField(
              label: 'Password',
              controller: _passwordController,
              isPassword: true,
              obscure: _obscurePassword,
              toggleObscure: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              focusNode: _passwordFocusNode,
            ),
            if (_showConfirmPassword)
              _editField(
                label: 'Konfirmasi Password',
                controller: _confirmPasswordController,
                isPassword: true,
                obscure: _obscureConfirm,
                toggleObscure: () {
                  setState(() => _obscureConfirm = !_obscureConfirm);
                },
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 1, 192, 255),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Update'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
