import 'package:shared_preferences/shared_preferences.dart';

class Auth {
  static String? artisanId;
  static String? name;
  static String? email;
  static String? address;
  static String? role;

  static Future<void> save(Map<String, dynamic> data) async {
    artisanId = data['artisan_id']?.toString();
    name = data['name']?.toString();
    email = data['email']?.toString();
    address = data['address']?.toString();
    role = data['role']?.toString();
    final p = await SharedPreferences.getInstance();
    if (artisanId != null) await p.setString('artisan_id', artisanId!);
    await p.setString('name', name ?? 'Artisan');
    await p.setString('email', email ?? '');
    await p.setString('address', address ?? '');
    await p.setString('role', role ?? 'artisan');
  }

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    artisanId = p.getString('artisan_id');
    name = p.getString('name');
    email = p.getString('email');
    address = p.getString('address');
    role = p.getString('role');
  }

  static Future<void> clear() async {
    artisanId = name = email = address = role = null;
    final p = await SharedPreferences.getInstance();
    await p.remove('artisan_id');
    await p.remove('name');
    await p.remove('email');
    await p.remove('address');
    await p.remove('role');
  }
}
