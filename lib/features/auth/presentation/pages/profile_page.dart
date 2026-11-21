import 'package:flutter/material.dart';

import '../../../../core/di/app_services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/app_user.dart';
import 'change_password_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.services, required this.user});

  final AppServices services;
  final AppUser user;

  Future<void> _openChangePassword(BuildContext context) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ChangePasswordPage(services: services),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: colors.primaryContainer,
                    child: Text(
                      user.name.isEmpty
                          ? '?'
                          : user.name.characters.first.toUpperCase(),
                      style: TextStyle(
                        fontSize: 32,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informasi Kontak',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Divider(height: 20),
                    _infoRow(Icons.person_outline_rounded, 'Nama', user.name),
                    const SizedBox(height: 12),
                    _infoRow(
                      Icons.alternate_email_rounded,
                      'Email',
                      user.email,
                    ),
                    const SizedBox(height: 12),
                    _infoRow(
                      Icons.phone_outlined,
                      'Nomor Telepon',
                      user.phone.isEmpty ? 'Belum diisi' : user.phone,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alamat Pengiriman',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Divider(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: AppColors.textTertiary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            user.hasAddress
                                ? user.formattedAddress
                                : 'Belum ada alamat pengiriman tersimpan.',
                            style: TextStyle(
                              color: user.hasAddress
                                  ? AppColors.textPrimary
                                  : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _openChangePassword(context),
              icon: const Icon(Icons.lock_reset_rounded),
              label: const Text('Ganti Kata Sandi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 20, color: AppColors.textTertiary),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
