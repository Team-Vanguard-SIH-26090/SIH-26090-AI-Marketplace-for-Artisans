import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';
import '../auth.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() => _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  static const background = Color(0xFFF5F2EB);
  static const primary = Color(0xFF9E4733);
  static const light = Color(0xFFEADCCF);
  static const textDark = Color(0xFF2C221E);
  static const muted = Color(0xFF8C7A70);

  final name = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();
  final phone = TextEditingController();
  bool editing = false;
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    name.text = Auth.name ?? '';
    email.text = Auth.email ?? '';
    address.text = Auth.address ?? '';
    _load();
  }

  Future<void> _load() async {
    if (Auth.artisanId == null) {
      setState(() => loading = false);
      return;
    }
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/artisans/${Auth.artisanId}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        name.text = (data['name'] ?? '').toString();
        email.text = (data['email'] ?? '').toString();
        address.text = (data['address'] ?? '').toString();
        phone.text = (data['phone'] ?? '').toString();
        await Auth.save({...data, 'artisan_id': Auth.artisanId});
      }
    } catch (_) {
      // Cached Auth values remain visible if the server is temporarily unavailable.
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _save() async {
    if (Auth.artisanId == null || name.text.trim().isEmpty || email.text.trim().isEmpty || address.text.trim().isEmpty) {
      _message('Name, email and address are required.');
      return;
    }
    setState(() => saving = true);
    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/artisans/${Auth.artisanId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name.text.trim(), 'email': email.text.trim(), 'address': address.text.trim(), 'phone': phone.text.trim()}),
      );
      if (response.statusCode != 200) throw Exception(_error(response.body));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await Auth.save({...data, 'artisan_id': Auth.artisanId});
      if (mounted) {
        setState(() => editing = false);
        _message('Profile updated successfully.');
      }
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String _error(String body) {
    try {
      return jsonDecode(body)['detail'].toString();
    } catch (_) {
      return 'Could not update profile';
    }
  }

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    address.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(title: const Text('Personal Information', style: TextStyle(color: textDark, fontWeight: FontWeight.w600)), backgroundColor: background, elevation: 0, iconTheme: const IconThemeData(color: textDark)),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(width: 90, height: 90, decoration: BoxDecoration(color: light, borderRadius: BorderRadius.circular(45)), child: const Icon(Icons.person, size: 48, color: primary)),
                  const SizedBox(height: 24),
                  _field(name, 'Name', Icons.person_outline),
                  _field(email, 'Email', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  _field(phone, 'Phone (optional)', Icons.phone_outlined, keyboardType: TextInputType.phone),
                  _field(address, 'Delivery Address', Icons.location_on_outlined, maxLines: 3),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, height: 52, child: editing
                      ? ElevatedButton.icon(onPressed: saving ? null : _save, icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_outlined), label: const Text('Save Information'), style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))
                      : OutlinedButton.icon(onPressed: () => setState(() => editing = true), icon: const Icon(Icons.edit_outlined), label: const Text('Edit Information'), style: OutlinedButton.styleFrom(foregroundColor: primary, side: const BorderSide(color: primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
                ],
              ),
            ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        enabled: editing,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: primary), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
      ),
    );
  }
}