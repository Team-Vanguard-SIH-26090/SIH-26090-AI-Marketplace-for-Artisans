import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';
import '../auth.dart';
import 'dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool passwordVisible = false;

  Future<void> signup() async {
    if (name.text.trim().isEmpty || email.text.trim().isEmpty || address.text.trim().isEmpty || password.text.length < 6) {
      _message('Enter your name, email, address and a password of at least 6 characters.');
      return;
    }
    setState(() => loading = true);
    try {
      final r = await http.post(Uri.parse('$apiBaseUrl/auth/signup'), body: {
        'name': name.text.trim(), 'email': email.text.trim(), 'address': address.text.trim(), 'password': password.text,
      });
      if (r.statusCode != 200) throw Exception(_error(r.body));
      await Auth.save(jsonDecode(r.body));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashboardScreen()), (_) => false);
    } catch (e) {
      if (mounted) _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _error(String body) {
    try { return jsonDecode(body)['detail'].toString(); } catch (_) { return 'Signup failed'; }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    address.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EB),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(28), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.auto_awesome, size: 54, color: Color(0xFF9E4733)),
          const SizedBox(height: 24),
          const Text('Create account', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF2C221E))),
          const SizedBox(height: 8),
          const Text('Start building your digital craft store.', style: TextStyle(color: Color(0xFF8C7A70))),
          const SizedBox(height: 32),
          _field(name, 'Name', Icons.person_outline),
          const SizedBox(height: 16),
          _field(email, 'Email', Icons.email_outlined),
          const SizedBox(height: 16),
          _field(address, 'Delivery Address', Icons.location_on_outlined, maxLines: 3),
          const SizedBox(height: 16),
          _field(password, 'Password', Icons.lock_outline, obscure: !passwordVisible, suffix: IconButton(onPressed: () => setState(() => passwordVisible = !passwordVisible), icon: Icon(passwordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined))),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
            onPressed: loading ? null : signup,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9E4733), foregroundColor: Colors.white),
            child: loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Sign Up'),
          )),
          Center(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Already have an account? Login'))),
        ],
      )),),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, {bool obscure = false, int maxLines = 1, Widget? suffix}) => TextField(
    controller: c, obscureText: obscure,
    maxLines: obscure ? 1 : maxLines,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), suffixIcon: suffix, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
  );
}
