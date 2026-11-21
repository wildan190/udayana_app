import 'package:flutter/material.dart';
import '../../../../core/di/app_services.dart';

class WithdrawDialog {
  static Future<void> show({
    required BuildContext context,
    required AppServices services,
    required String Function(int) moneyFormatter,
    required void Function(String) showMessage,
  }) async {
    final formKey = GlobalKey<FormState>();
    String selectedBank = 'bca';
    final accountName = TextEditingController();
    final accountNumber = TextEditingController();
    final amount = TextEditingController();

    final banks = [
      {'code': 'bca', 'label': 'BCA (Bank Central Asia)'},
      {'code': 'mandiri', 'label': 'Bank Mandiri'},
      {'code': 'bni', 'label': 'BNI (Bank Negara Indonesia)'},
      {'code': 'bri', 'label': 'BRI (Bank Rakyat Indonesia)'},
      {'code': 'cimb', 'label': 'CIMB Niaga'},
      {'code': 'permata', 'label': 'Bank Permata'},
      {'code': 'danamon', 'label': 'Bank Danamon'},
    ];

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance_rounded,
                        color: Color(0xFF002E69),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Penarikan Dana (Withdraw)',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tarik saldo penjualan Midtrans ke rekening bank Admin via Iris Payouts.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    value: selectedBank,
                    decoration:
                        const InputDecoration(labelText: 'Nama Bank Tujuan'),
                    items: banks
                        .map(
                          (b) => DropdownMenuItem(
                            value: b['code'],
                            child: Text(b['label']!),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedBank = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: accountName,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama Pemilik Rekening',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Nama pemilik rekening wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: accountNumber,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Rekening Bank',
                      prefixIcon: Icon(Icons.numbers_rounded),
                    ),
                    validator: (v) {
                      final val = (v ?? '').trim();
                      return val.isEmpty || !RegExp(r'^\d+$').hasMatch(val)
                          ? 'Nomor rekening harus berupa angka'
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Penarikan (Rp)',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    validator: (v) {
                      final val = int.tryParse((v ?? '').trim()) ?? 0;
                      return val < 10000
                          ? 'Minimal penarikan adalah Rp 10.000'
                          : null;
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Tarik Dana via Midtrans Iris'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(context, true);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (submitted != true || !context.mounted) return;

    try {
      final amountValue = int.parse(amount.text.trim());
      final result = await services.withdraw(
        bankName: selectedBank,
        accountName: accountName.text.trim(),
        accountNumber: accountNumber.text.trim(),
        amountCents: amountValue * 100,
      );
      if (!context.mounted) return;
      final refId = result['reference_id'] as String? ?? '-';
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Penarikan Dana Berhasil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Permintaan penarikan sebesar ${moneyFormatter(amountValue * 100)} telah dikirim ke Midtrans Iris.',
              ),
              const SizedBox(height: 10),
              Text('Bank: ${selectedBank.toUpperCase()}'),
              Text('Pemilik: ${accountName.text.trim()}'),
              Text('No. Rek: ${accountNumber.text.trim()}'),
              const SizedBox(height: 10),
              Text(
                'Reference ID: $refId',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on Exception catch (error) {
      if (context.mounted) showMessage(error.toString());
    }
  }
}
