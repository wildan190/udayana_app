import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/app_services.dart';
import '../../../../core/network/session_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/repositories/auth_repository.dart';
import '../state/auth_controller.dart';
import '../state/auth_event.dart';
import '../state/auth_state.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.services});

  final AppServices services;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final AuthController _controller;
  late final TextEditingController _email;
  late final TextEditingController _password;
  var _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(
      text: kDebugMode ? 'buyer@udayana.local' : '',
    );
    _password = TextEditingController(
      text: kDebugMode ? 'buyer123' : '',
    );
    _controller = AuthController(
      widget.services.signIn,
      widget.services.registerBuyer,
      (token) => widget.services.api.token = token,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _useDemo(String role) {
    final isAdmin = role == 'admin';
    _email.text = isAdmin ? 'admin@udayana.com' : 'buyer@udayana.local';
    _password.text = isAdmin ? 'admin@2025' : 'buyer123';
  }

  Future<void> _signIn() async {
    await _controller.dispatch(
      SignInRequested(email: _email.text, password: _password.text),
    );
    if (!mounted) return;
    final session = _controller.state.session;
    if (session != null) {
      if (_rememberMe) {
        await SessionStorage.save(token: session.token, user: session.user);
      }
      Navigator.pop(context, session);
    }
  }

  Future<void> _openRegister() async {
    final session = await Navigator.of(context).push<AuthSession>(
      MaterialPageRoute<AuthSession>(
        builder: (_) => RegisterPage(services: widget.services),
      ),
    );
    if (session != null && mounted) Navigator.pop(context, session);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => _buildForm(context, _controller.state),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: AppRadius.controlAll,
          child: Image.asset(
            'assets/images/logo.png',
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Belanja harian,\nlebih sederhana.',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w700, height: 1.12),
        ),
        const SizedBox(height: 12),
        Text(
          'Masuk ke Udayana Market untuk kebutuhan sehari-hari.',
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.alternate_email_rounded),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _password,
          obscureText: true,
          onSubmitted: (_) => _signIn(),
          decoration: const InputDecoration(
            labelText: 'Kata sandi',
            prefixIcon: Icon(Icons.lock_outline_rounded),
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 12),
          Text(state.error!, style: const TextStyle(color: AppColors.error)),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (val) => setState(() => _rememberMe = val ?? true),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                child: const Text(
                  'Ingat saya (Jangan logout otomatis)',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: state.isLoading ? null : _signIn,
            child: state.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Masuk'),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: state.isLoading ? null : _openRegister,
            child: const Text('Belum punya akun? Daftar pembeli'),
          ),
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 24),
          Text(
            'Akun demo (Debug Mode)',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _useDemo('buyer'),
                  icon: const Icon(Icons.person_outline_rounded),
                  label: const Text('Pembeli'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _useDemo('admin'),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Admin'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Gunakan tombol akun demo untuk mengisi email dan kata sandi.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}
