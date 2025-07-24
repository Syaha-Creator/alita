import 'package:flutter/material.dart';

class CheckoutDialogResult {
  final String name;
  final String phone;
  final String email;
  final bool isTakeAway;
  CheckoutDialogResult({
    required this.name,
    required this.phone,
    required this.email,
    required this.isTakeAway,
  });
}

class CheckoutUserInfoDialog extends StatefulWidget {
  const CheckoutUserInfoDialog({super.key});
  @override
  State<CheckoutUserInfoDialog> createState() => _CheckoutUserInfoDialogState();
}

class _CheckoutUserInfoDialogState extends State<CheckoutUserInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isTakeAway = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Informasi Customer'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                keyboardType: TextInputType.phone,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Shipment'),
                      value: false,
                      groupValue: _isTakeAway,
                      onChanged: (val) {
                        setState(() => _isTakeAway = false);
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Take Away'),
                      value: true,
                      groupValue: _isTakeAway,
                      onChanged: (val) {
                        setState(() => _isTakeAway = true);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(
                context,
                CheckoutDialogResult(
                  name: _nameController.text,
                  phone: _phoneController.text,
                  email: _emailController.text,
                  isTakeAway: _isTakeAway,
                ),
              );
            }
          },
          child: const Text('Lanjut'),
        ),
      ],
    );
  }
}
