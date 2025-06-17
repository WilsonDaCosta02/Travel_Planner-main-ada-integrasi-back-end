import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:project_travelplanner/graphql/mutation/registerUser.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool _obscureText = true;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> registerUser() async {
    final client = GraphQLProvider.of(context).value;

    final result = await client.mutate(
      MutationOptions(
        document: gql(RegisterUser.createUserMutation),
        variables: {
          'nama': nameController.text,
          'no_hp': phoneController.text,
          'email': emailController.text,
          'password': passwordController.text,
        },
      ),
    );

    if (result.hasException) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.exception.toString())));
      return;
    }

    // Jika sukses
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Register Berhasil!")));
    Navigator.pop(context); // tutup dialog register
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: SingleChildScrollView(
        child: Container(
          width: 500,
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo atau Gambar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 34, 102, 141),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Image.asset('assets/images/Frame 1.png'),
              ),
              SizedBox(height: 15),
              Divider(thickness: 1, color: Colors.grey),

              // Input Fields
              buildInputField(
                icon: Icons.person,
                label: 'Nama',
                hintText: 'Nama lengkap',
                controller: nameController,
              ),
              SizedBox(height: 10),
              buildInputField(
                icon: Icons.phone,
                label: 'HP',
                hintText: '08xxxxxxxxxx',
                controller: phoneController,
              ),
              SizedBox(height: 10),
              buildInputField(
                icon: Icons.email,
                label: 'Email',
                hintText: 'example@gmail.com',
                controller: emailController,
              ),
              SizedBox(height: 10),
              buildInputField(
                icon: Icons.key,
                label: 'Password',
                hintText: 'Masukkan Password',
                controller: passwordController,
                isPassword: true,
                obscureText: _obscureText,
                toggleObscure: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),

              SizedBox(height: 20),

              // Tombol Register
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 99, 88, 220),
                  minimumSize: Size(300, 35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: registerUser,
                child: Text('Register', style: TextStyle(color: Colors.white)),
              ),

              SizedBox(height: 10),

              // Link ke Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Do you have an account? ',
                    style: TextStyle(fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Back to Login',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 114, 33, 243),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInputField({
    required IconData icon,
    required String label,
    required String hintText,
    required TextEditingController controller,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? toggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 200, 194, 194),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword ? obscureText : false,
            keyboardType:
                isPassword
                    ? TextInputType.visiblePassword
                    : TextInputType.emailAddress,
            style: const TextStyle(color: Colors.black, fontSize: 16),
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 9,
              ),
              suffixIcon:
                  isPassword && toggleObscure != null
                      ? IconButton(
                        onPressed: toggleObscure,
                        icon: Icon(
                          obscureText ? Icons.visibility : Icons.visibility_off,
                        ),
                      )
                      : null,
            ),
          ),
        ),
      ],
    );
  }
}
