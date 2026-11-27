import 'package:flutter/material.dart';

import '../../../../core/di/app_services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../store/presentation/pages/settings_page.dart';
import '../../domain/entities/app_user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.services, required this.user});

  final AppServices services;
  final AppUser user;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late AppUser _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  Future<void> _openSettings(BuildContext context) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => SettingsPage(services: widget.services, user: _currentUser),
      ),
    );
    if (deleted == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _openEditBankAccount() async {
    final formKey = GlobalKey<FormState>();
    final bankName = TextEditingController(
      text: _currentUser.bankName.isNotEmpty
          ? _currentUser.bankName.toLowerCase()
          : 'bca',
    );
    final accountName = TextEditingController(text: _currentUser.accountName);
    final accountNumber = TextEditingController(
      text: _currentUser.accountNumber,
    );

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Rekening Bank untuk Refund',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Masukkan rekening bank Anda untuk pencairan dana otomatis via Midtrans IRIS jika pesanan dibatalkan.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value:
                      [
                            'bca',
                            'mandiri',
                            'bni',
                            'bri',
                            'permata',
                            'cimb',
                          ].contains(bankName.text.toLowerCase())
                          ? bankName.text.toLowerCase()
                          : 'bca',
                  decoration: const InputDecoration(labelText: 'Nama Bank'),
                  items: const [
                    DropdownMenuItem(
                      value: 'bca',
                      child: Text('BCA (Bank Central Asia)'),
                    ),
                    DropdownMenuItem(
                      value: 'mandiri',
                      child: Text('Bank Mandiri'),
                    ),
                    DropdownMenuItem(
                      value: 'bni',
                      child: Text('BNI (Bank Negara Indonesia)'),
                    ),
                    DropdownMenuItem(
                      value: 'bri',
                      child: Text('BRI (Bank Rakyat Indonesia)'),
                    ),
                    DropdownMenuItem(
                      value: 'permata',
                      child: Text('Bank Permata'),
                    ),
                    DropdownMenuItem(
                      value: 'cimb',
                      child: Text('CIMB Niaga'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) bankName.text = val;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: accountName,
                  decoration: const InputDecoration(
                    labelText: 'Nama Pemilik Rekening',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: accountNumber,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Rekening',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('Simpan Rekening'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved != true || !mounted) return;

    try {
      await widget.services.updateBankAccount({
        'bank_name': bankName.text.trim(),
        'account_name': accountName.text.trim(),
        'account_number': accountNumber.text.trim(),
      });
      setState(() {
        _currentUser = AppUser(
          id: _currentUser.id,
          name: _currentUser.name,
          email: _currentUser.email,
          role: _currentUser.role,
          phone: _currentUser.phone,
          province: _currentUser.province,
          city: _currentUser.city,
          district: _currentUser.district,
          subdistrict: _currentUser.subdistrict,
          rtRw: _currentUser.rtRw,
          postalCode: _currentUser.postalCode,
          address: _currentUser.address,
          bankName: bankName.text.trim(),
          accountName: accountName.text.trim(),
          accountNumber: accountNumber.text.trim(),
          is2FAEnabled: _currentUser.is2FAEnabled,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rekening bank berhasil diperbarui.')),
      );
    } on Exception catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          IconButton(
            tooltip: 'Pengaturan Aplikasi',
            onPressed: () => _openSettings(context),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
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
                      _currentUser.name.isEmpty
                          ? '?'
                          : _currentUser.name.characters.first.toUpperCase(),
                      style: TextStyle(
                        fontSize: 32,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentUser.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentUser.email,
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
                    _infoRow(Icons.person_outline_rounded, 'Nama', _currentUser.name),
                    const SizedBox(height: 12),
                    _infoRow(
                      Icons.alternate_email_rounded,
                      'Email',
                      _currentUser.email,
                    ),
                    const SizedBox(height: 12),
                    _infoRow(
                      Icons.phone_outlined,
                      'Nomor Telepon',
                      _currentUser.phone.isEmpty ? 'Belum diisi' : _currentUser.phone,
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
                            _currentUser.hasAddress
                                ? _currentUser.formattedAddress
                                : 'Belum ada alamat pengiriman tersimpan.',
                            style: TextStyle(
                              color: _currentUser.hasAddress
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
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Rekening Bank (Refund)',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: _openEditBankAccount,
                          child: Text(
                            _currentUser.accountNumber.isNotEmpty
                                ? 'Ubah'
                                : 'Tambah',
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 10),
                    if (_currentUser.accountNumber.isEmpty)
                      const Text(
                        'Belum ada rekening bank untuk pencairan dana refund.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow(
                            Icons.account_balance_rounded,
                            'Bank',
                            _currentUser.bankName.toUpperCase(),
                          ),
                          const SizedBox(height: 8),
                          _infoRow(
                            Icons.badge_outlined,
                            'Pemilik',
                            _currentUser.accountName,
                          ),
                          const SizedBox(height: 8),
                          _infoRow(
                            Icons.credit_card_rounded,
                            'No. Rekening',
                            _currentUser.accountNumber,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.settings_outlined, color: AppColors.primary),
                title: const Text(
                  'Pengaturan Aplikasi',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Keamanan 2FA, Optimalisasi Baterai, & Tentang Kami'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _openSettings(context),
              ),
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
