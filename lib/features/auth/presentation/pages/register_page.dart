import 'package:flutter/material.dart';

import '../../../../core/di/app_services.dart';
import '../../../../core/network/session_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../state/auth_controller.dart';
import '../state/auth_event.dart';
import '../state/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.services});

  final AppServices services;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  late final AuthController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AuthController(
      widget.services.signIn,
      widget.services.registerBuyer,
      (token) => widget.services.api.token = token,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_controller.state.isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    await _controller.dispatch(
      RegisterBuyerRequested(
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        password: _password.text,
      ),
    );
    if (!mounted) return;
    final session = _controller.state.session;
    if (session != null) {
      await SessionStorage.save(token: session.token, user: session.user);
      if (!mounted) return;
      Navigator.of(context).pop(session);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar pembeli')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) =>
                    _buildForm(context, _controller.state),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    AuthState state,
  ) => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ClipRRect(
            borderRadius: AppRadius.controlAll,
            child: Image.asset(
              'assets/images/logo.png',
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Buat akun baru',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Daftar untuk menyimpan keranjang dan melakukan checkout COD.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nama lengkap'),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Nama wajib diisi' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
          validator: (value) {
            final email = value?.trim() ?? '';
            return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                ? null
                : 'Masukkan email yang valid';
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Nomor telepon (opsional)',
          ),
          validator: (value) => (value?.length ?? 0) > 40
              ? 'Nomor telepon terlalu panjang'
              : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Kata sandi'),
          validator: (value) {
            final length = value?.length ?? 0;
            if (length < 8) return 'Kata sandi minimal 8 karakter';
            if (length > 72) return 'Kata sandi maksimal 72 karakter';
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _confirmPassword,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Ulangi kata sandi'),
          validator: (value) =>
              value != _password.text ? 'Kata sandi tidak sama' : null,
        ),
        if (state.error != null) ...[
          const SizedBox(height: 12),
          Text(
            state.error!,
            style: const TextStyle(color: AppColors.error),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: state.isLoading ? null : _register,
          child: state.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Daftar dan mulai belanja'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: state.isLoading ? null : () => Navigator.pop(context),
          child: const Text('Sudah punya akun? Masuk'),
        ),
      ],
    ),
  );
}
