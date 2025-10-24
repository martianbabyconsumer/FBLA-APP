import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() => _loading = true);
    try {
      await context.read<AuthService>().signUpWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
            _displayController.text.trim(),
          );
      Navigator.of(context).pop(); // go back to login
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign up failed: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _displayController, decoration: const InputDecoration(labelText: 'Display name')),
            const SizedBox(height: 12),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _loading ? null : _signUp, child: _loading ? const CircularProgressIndicator() : const Text('Create account')),
          ],
        ),
      ),
    );
  }
}
