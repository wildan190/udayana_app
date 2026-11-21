import 'package:flutter/material.dart';

import '../../../../core/di/app_services.dart';
import '../../../../core/theme/app_theme.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key, required this.services});

  final AppServices services;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  var _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await widget.services.changePassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kata sandi berhasil diubah.')),
      );
      Navigator.pop(context, true);
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ganti kata sandi')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Keamanan Akun',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Masukkan kata sandi saat ini dan kata sandi baru Anda.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _currentPassword,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Kata sandi saat ini',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty
                              ? 'Kata sandi saat ini wajib diisi'
                              : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _newPassword,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Kata sandi baru',
                        prefixIcon: Icon(Icons.lock_reset_rounded),
                      ),
                      validator: (value) {
                        final len = value?.length ?? 0;
                        if (len < 8) return 'Kata sandi baru minimal 8 karakter';
                        if (len > 72) return 'Kata sandi maksimal 72 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmPassword,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Ulangi kata sandi baru',
                        prefixIcon: Icon(Icons.lock_reset_rounded),
                      ),
                      validator: (value) =>
                          value != _newPassword.text
                              ? 'Konfirmasi kata sandi tidak sama'
                              : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Simpan Kata Sandi Baru'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
