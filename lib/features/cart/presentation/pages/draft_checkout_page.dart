import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/auth_service.dart';
import 'checkout_pages.dart';

class DraftCheckoutPage extends StatefulWidget {
  const DraftCheckoutPage({super.key});
  @override
  State<DraftCheckoutPage> createState() => _DraftCheckoutPageState();
}

class _DraftCheckoutPageState extends State<DraftCheckoutPage> {
  List<Map<String, dynamic>> _drafts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final userId = await AuthService.getCurrentUserId();
    if (userId == null) {
      setState(() {
        _drafts = [];
        _loading = false;
      });
      return;
    }
    final drafts = prefs.getStringList('checkout_drafts_$userId') ?? [];
    setState(() {
      _drafts =
          drafts.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      _loading = false;
    });
  }

  void _continueDraft(Map<String, dynamic> draft) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await AuthService.getCurrentUserId();
    if (userId == null) return;
    final key = 'checkout_drafts_$userId';
    final drafts = prefs.getStringList(key) ?? [];
    // Temukan dan hapus draft yang sesuai
    final draftString = drafts.firstWhere(
      (e) => jsonDecode(e)['savedAt'] == draft['savedAt'],
      orElse: () => '',
    );
    if (draftString.isNotEmpty) {
      drafts.remove(draftString);
      await prefs.setStringList(key, drafts);
      setState(() {
        _drafts.removeWhere((d) => d['savedAt'] == draft['savedAt']);
      });
    }
    // Navigasi ke halaman checkout
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPages(
          userName: draft['customerName'],
          userPhone: draft['customerPhone'],
          userEmail: draft['email'],
          userAddress: draft['customerAddress'],
          isTakeAway: draft['isTakeAway'] ?? false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Draft Checkout')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _drafts.isEmpty
              ? Center(child: Text('Belum ada draft checkout'))
              : ListView.separated(
                  itemCount: _drafts.length,
                  separatorBuilder: (_, __) => Divider(),
                  itemBuilder: (context, i) {
                    final draft = _drafts[i];
                    final isTakeAway = draft['isTakeAway'] == true;
                    return ListTile(
                      title: Text(draft['customerName'] ?? '-'),
                      subtitle: Text(
                        'Disimpan: ${draft['savedAt'] ?? '-'}\nTotal: Rp ${draft['grandTotal'] ?? '-'}',
                      ),
                      isThreeLine: true,
                      trailing: ElevatedButton(
                        onPressed: () => _continueDraft(draft),
                        child: Text('Lanjutkan'),
                      ),
                    );
                  },
                ),
    );
  }
}
 