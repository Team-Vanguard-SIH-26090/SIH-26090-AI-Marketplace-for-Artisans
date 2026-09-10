import 'dashboard_screen.dart';
import 'signup_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api.dart';
import '../auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool passwordVisible = false;

  Future<void> _login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter email and password.')));
      return;
    }
    setState(() => loading = true);
    try {
      final r = await http.post(Uri.parse('$apiBaseUrl/auth/login'), body: {'email': email.text.trim(), 'password': password.text});
      if (r.statusCode != 200) throw Exception(_error(r.body));
      await Auth.save(jsonDecode(r.body));
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally { if (mounted) setState(() => loading = false); }
  }

  String _error(String body) { try { return jsonDecode(body)['detail'].toString(); } catch (_) { return 'Login failed'; } }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _forgotPassword() async {
    final emailController = TextEditingController(text: email.text.trim());
    final requestedEmail = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Registered email')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, emailController.text.trim()), child: const Text('Send OTP')),
        ],
      ),
    );
    emailController.dispose();
    if (requestedEmail == null || requestedEmail.isEmpty) return;
    try {
      final response = await http.post(Uri.parse('$apiBaseUrl/auth/forgot-password'), body: {'email': requestedEmail});
      if (response.statusCode != 200) throw Exception(_error(response.body));
      if (!mounted) return;
      final otp = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          final otpController = TextEditingController();
          return AlertDialog(
            title: const Text('Enter the 4-digit OTP'),
            content: TextField(controller: otpController, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: 'OTP')),
            actions: [
              TextButton(onPressed: () { otpController.dispose(); Navigator.pop(dialogContext); }, child: const Text('Cancel')),
              ElevatedButton(onPressed: () { final value = otpController.text.trim(); otpController.dispose(); Navigator.pop(dialogContext, value); }, child: const Text('Verify')),
            ],
          );
        },
      );
      if (otp == null || otp.length != 4) return;
      if (!mounted) return;
      final newPasswordController = TextEditingController();
      final newPassword = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Choose a new password'),
          content: TextField(controller: newPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(dialogContext, newPasswordController.text), child: const Text('Update')),
          ],
        ),
      );
      newPasswordController.dispose();
      if (newPassword == null || newPassword.length < 6) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters.')));
        return;
      }
      final resetResponse = await http.post(Uri.parse('$apiBaseUrl/auth/reset-password'), body: {'email': requestedEmail, 'otp': otp, 'new_password': newPassword});
      if (resetResponse.statusCode != 200) throw Exception(_error(resetResponse.body));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated. You can now log in.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EB), // Warm Sand
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),

              // App branding
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9E4733), // Terracotta
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'CraftConnect',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C221E), // Espresso
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              const Text(
                'Welcome back!',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C221E),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue your digital journey.',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF8C7A70),
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Email or Mobile Number',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C221E),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter your email or mobile number',
                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF9E4733)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C221E),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: password,
                obscureText: !passwordVisible,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF9E4733)),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => passwordVisible = !passwordVisible),
                    icon: Icon(passwordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFF8C7A70)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                   onPressed: loading ? null : _forgotPassword,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Color(0xFF9E4733),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9E4733),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: TextButton(
                  onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())); },
                  child: const Text.rich(
                    TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(
                        color: Color(0xFF8C7A70),
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(
                            color: Color(0xFF9E4733),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: TextButton(
                  onPressed: loading ? null : () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
                  },
                  child: const Text(
                    'Continue as Guest',
                    style: TextStyle(
                      color: Color(0xFF8C7A70),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}