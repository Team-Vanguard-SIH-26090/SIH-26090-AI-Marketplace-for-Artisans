import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';
import '../auth.dart';
import '../l10n/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const background = Color(0xFFF5F2EB);
  static const primary = Color(0xFF9E4733);
  static const light = Color(0xFFEADCCF);
  static const textDark = Color(0xFF2C221E);
  static const muted = Color(0xFF8C7A70);

  List<Map<String, dynamic>> notifications = [];
  bool loading = true;
  String? error;

  int get unreadCount => notifications.where((item) => item['read'] != true).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (Auth.artisanId == null) {
      setState(() => loading = false);
      return;
    }
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/notifications?user_id=${Uri.encodeComponent(Auth.artisanId!)}'));
      if (response.statusCode != 200) throw Exception('Could not load notifications');
      notifications = List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } catch (exception) {
      error = exception.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _markRead(Map<String, dynamic> notification) async {
    if (notification['read'] == true || Auth.artisanId == null) return;
    final id = notification['_id'];
    final response = await http.patch(Uri.parse('$apiBaseUrl/notifications/$id/read?user_id=${Uri.encodeComponent(Auth.artisanId!)}'));
    if (response.statusCode == 200 && mounted) {
      setState(() => notification['read'] = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(context.strings.text('notifications'), style: const TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        backgroundColor: background,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        actions: [
          if (unreadCount > 0)
            Padding(padding: const EdgeInsets.only(right: 18), child: Center(child: Text('$unreadCount unread', style: const TextStyle(color: primary, fontWeight: FontWeight.w600)))),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : error != null
              ? Center(child: Text(error!, style: const TextStyle(color: muted)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: notifications.isEmpty
                      ? ListView(children: const [SizedBox(height: 220), Center(child: Text('You are all caught up.', style: TextStyle(color: muted)))])
                      : ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            _section('Today', notifications.where((item) => _age(item) < 1).toList()),
                            _section('Earlier', notifications.where((item) => _age(item) >= 1).toList()),
                          ],
                        ),
                ),
    );
  }

  int _age(Map<String, dynamic> item) {
    final created = DateTime.tryParse(item['created_at']?.toString() ?? '');
    return created == null ? 99 : DateTime.now().difference(created.toLocal()).inDays;
  }

  Widget _section(String title, List<Map<String, dynamic>> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(title, style: const TextStyle(color: muted, fontWeight: FontWeight.w600))),
      ...items.map((item) => GestureDetector(onTap: () => _markRead(item), child: _notificationCard(item))),
      const SizedBox(height: 18),
    ]);
  }

  Widget _notificationCard(Map<String, dynamic> item) {
    final kind = item['kind']?.toString() ?? '';
    final icon = kind == 'order_placed' ? Icons.shopping_bag_outlined : kind == 'order_dispatched' ? Icons.local_shipping_outlined : kind == 'weekly_tip' ? Icons.lightbulb_outline : Icons.auto_awesome;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: item['read'] == true ? Colors.white : const Color(0xFFFFF8F2), borderRadius: BorderRadius.circular(18), border: Border.all(color: item['read'] == true ? Colors.transparent : primary.withOpacity(0.25))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 46, height: 46, decoration: BoxDecoration(color: light, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: primary)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(item['title']?.toString() ?? 'Notification', style: const TextStyle(fontWeight: FontWeight.w600, color: textDark))), if (item['read'] != true) const CircleAvatar(radius: 4, backgroundColor: primary)]),
          const SizedBox(height: 5),
          Text(item['message']?.toString() ?? '', style: const TextStyle(color: muted, height: 1.4)),
        ])),
      ]),
    );
  }
}