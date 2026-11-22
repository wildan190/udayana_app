import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../../core/di/app_services.dart';

class MidtransDialog {
  static Future<void> show({
    required BuildContext context,
    required Order order,
    required AppServices services,
    required String Function(int) moneyFormatter,
  }) async {
    Map<String, dynamic> resp = order.midtransResponse;
    if (resp.isEmpty) {
      try {
        resp = await services.getPaymentDetails(order.id);
      } catch (_) {}
    }
    final isQris = order.paymentMethod == 'MIDTRANS_QRIS';

    final vaNumbers = resp['va_numbers'] as List<dynamic>?;
    final vaNumber = vaNumbers != null && vaNumbers.isNotEmpty
        ? (vaNumbers.first as Map<String, dynamic>)['va_number']?.toString()
        : null;
    final bank = vaNumbers != null && vaNumbers.isNotEmpty
        ? (vaNumbers.first as Map<String, dynamic>)['bank']?.toString()
        : null;

    final actions = resp['actions'] as List<dynamic>?;
    final qrAction = actions?.firstWhere(
      (a) => (a as Map<String, dynamic>)['name'] == 'generate-qr-code',
      orElse: () => null,
    ) as Map<String, dynamic>?;
    final qrUrl = qrAction?['url'] as String?;
    final qrString = resp['qr_string'] as String?;

    final itemSummary = order.items
        .map((item) => '${item.quantity}x ${item.productName}')
        .join(', ');

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isQris ? 'Pembayaran Midtrans QRIS' : 'Pembayaran Virtual Account',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nominal Pembayaran:',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                moneyFormatter(order.totalCents),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Item / Barang:',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                itemSummary.isEmpty ? 'Pesanan #${order.id}' : itemSummary,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Divider(height: 24),
              if (isQris) ...[
                const Text(
                  'Silakan scan QRIS di bawah ini untuk melakukan pembayaran:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (qrUrl != null)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        qrUrl,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Text('QR Code tidak dapat dimuat'),
                      ),
                    ),
                  )
                else if (qrString != null)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.qr_code_2_rounded,
                            size: 56,
                            color: Color(0xFF002E69),
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            qrString,
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const Text(
                    'Detail QRIS belum tersedia. Pembayaran sedang disiapkan oleh Midtrans, silakan coba lagi sebentar lagi.',
                  ),
              ] else ...[
                Text(
                  'Silakan salin nomor Virtual Account (${bank?.toUpperCase() ?? 'VA'}) di bawah ini untuk melakukan pembayaran:',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (vaNumber != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            vaNumber,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Salin No. VA',
                          icon: const Icon(Icons.copy_rounded, size: 20),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: vaNumber));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Nomor Virtual Account berhasil disalin!',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                else
                  const Text(
                    'Nomor Virtual Account belum tersedia. Silakan muat ulang atau hubungi penjual.',
                  ),
              ],
            ],
          ),
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
}
