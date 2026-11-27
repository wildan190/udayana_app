import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/app_services.dart';
import '../../../../core/network/session_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/pages/change_password_page.dart';
import 'about_us_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.services,
    required this.user,
  });

  final AppServices services;
  final AppUser user;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _is2faEnabled;

  @override
  void initState() {
    super.initState();
    _is2faEnabled = widget.user.is2FAEnabled;
  }

  Future<void> _openChangePassword(BuildContext context) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ChangePasswordPage(services: widget.services),
      ),
    );
  }

  Future<void> _openAboutUs(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const AboutUsPage(),
      ),
    );
  }

  Future<void> _openBatterySettings() async {
    const url = 'package:com.udayana_store';
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    } catch (_) {}

    try {
      await launchUrl(Uri.parse('android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS'));
    } catch (_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Optimalisasi Baterai Background'),
          content: const Text(
            'Agar notifikasi dan sinkronisasi pesanan admin berjalan lancar tanpa terbunuh oleh sistem Android, silakan:\n\n1. Buka Pengaturan (Settings) HP.\n2. Pilih Aplikasi > Udayana Store.\n3. Pilih Baterai (Battery) > Set ke "Tidak dibatasi" (Unrestricted).',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _viewBackupCodes() async {
    try {
      final codes = await widget.services.getBackupCodes();
      if (!mounted) return;
      await _showBackupCodesDialog(context, codes);
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil kode cadangan: $e')),
      );
    }
  }

  Future<void> _showBackupCodesDialog(BuildContext context, List<String> codes) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Kode Cadangan 2FA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Simpan kode cadangan ini di tempat yang aman. Setiap kode hanya dapat digunakan sekali jika Anda kehilangan akses ke email Anda.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...codes.map((code) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.fill,
                  borderRadius: AppRadius.controlAll,
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            )),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Akun?'),
        content: const Text(
          'Seluruh data profil, alamat, keranjang, dan riwayat pesanan Anda akan dihapus secara permanen.\n\nTindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await widget.services.deleteAccount();
      widget.services.api.token = null;
      await SessionStorage.clear();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Akun Anda telah berhasil dihapus.')),
      );
      navigator.pop(true);
    } on Exception catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menghapus akun: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Aplikasi')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionHeader('Keamanan Akun'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                    title: const Text('Ganti Kata Sandi'),
                    subtitle: const Text('Perbarui kata sandi akun Anda'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _openChangePassword(context),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.security_rounded, color: AppColors.primary),
                    title: const Text('Verifikasi 2 Langkah (2FA)'),
                    subtitle: const Text('Kirim kode OTP via email saat login'),
                    value: _is2faEnabled,
                    onChanged: (val) async {
                      final messenger = ScaffoldMessenger.of(context);
                      setState(() => _is2faEnabled = val);
                      try {
                        final codes = await widget.services.toggle2fa(enabled: val);
                        if (!mounted) return;
                        if (val && codes.isNotEmpty) {
                          await _showBackupCodesDialog(context, codes);
                        }
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              val
                                  ? 'Verifikasi 2 Langkah diaktifkan.'
                                  : 'Verifikasi 2 Langkah dinonaktifkan.',
                            ),
                          ),
                        );
                      } on Exception catch (e) {
                        if (!mounted) return;
                        setState(() => _is2faEnabled = !val);
                        messenger.showSnackBar(
                          SnackBar(content: Text('Gagal mengubah status 2FA: $e')),
                        );
                      }
                    },
                  ),
                  if (_is2faEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.vpn_key_rounded, color: AppColors.primary),
                      title: const Text('Kode Cadangan 2FA'),
                      subtitle: const Text('Lihat kode pemulihan sekali pakai'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _viewBackupCodes,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionHeader('Notifikasi & Performa'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.battery_charging_full_rounded, color: AppColors.primary),
                    title: const Text('Optimalisasi Baterai Background'),
                    subtitle: const Text('Cek izin daya agar notifikasi tidak dimatikan'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _openBatterySettings,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionHeader('Informasi & Akun'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                    title: const Text('Tentang Kami'),
                    subtitle: const Text('Info pengembang, versi, & pengembang'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _openAboutUs(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                    title: const Text(
                      'Hapus Akun',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Hapus akun Anda secara permanen'),
                    onTap: () => _confirmAndDeleteAccount(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
