import '../auth/auth_service.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  void signUp() async {
    final email = emailController.text;
    final pass = passwordController.text;
    final confirmPass = confirmPasswordController.text;

    if (confirmPass != pass) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords don't match")));
      return;
    }

    try {
      authService.signUpWithEmailPassword(email, pass);

      Navigator.pop(context); // Pop when finished sign up
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error:$e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 50),
        children: [
          // email
          TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: "Email"),
          ),
          // password
          TextField(
            controller: passwordController,
            decoration: const InputDecoration(labelText: "Password"),
          ),
          // confirm password
          TextField(
            controller: confirmPasswordController,
            decoration: const InputDecoration(labelText: "Password"),
          ),
          const SizedBox(height: 12),
          //login
          ElevatedButton(onPressed: signUp, child: const Text("Sign Up")),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
