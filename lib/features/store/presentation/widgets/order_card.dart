import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../orders/domain/entities/order.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.isAdmin,
    required this.moneyFormatter,
    required this.onShowMidtransDetails,
    required this.onBuyAgain,
    required this.onUpdateStatus,
    required this.onSimulatePayment,
    required this.onRequestCancellation,
    required this.onApproveCancellation,
    required this.onRejectCancellation,
  });

  final Order order;
  final bool isAdmin;
  final String Function(int) moneyFormatter;
  final VoidCallback onShowMidtransDetails;
  final VoidCallback onBuyAgain;
  final ValueChanged<String> onUpdateStatus;
  final VoidCallback onSimulatePayment;
  final VoidCallback onRequestCancellation;
  final VoidCallback onApproveCancellation;
  final VoidCallback onRejectCancellation;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pesanan #${order.id}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(child: _buildStatusChip(order.status)),
              ],
            ),
            if (isAdmin && order.customerName.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                'Pembeli: ${order.customerName}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            if (isAdmin &&
                order.paymentMethod.startsWith('MIDTRANS') &&
                order.status != 'cancelled') ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: order.status != 'pending'
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: AppRadius.controlAll,
                ),
                child: Row(
                  children: [
                    Icon(
                      order.status != 'pending'
                          ? Icons.check_circle_rounded
                          : Icons.hourglass_top_rounded,
                      size: 16,
                      color: order.status != 'pending'
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order.status != 'pending'
                          ? 'Status Pembayaran: Lunas (Midtrans)'
                          : 'Status Pembayaran: Menunggu Pembayaran Midtrans',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: order.status != 'pending'
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Alamat Pengiriman: ${order.shippingAddress.isNotEmpty ? order.shippingAddress : "Mengikuti profil buyer"}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              order.items
                  .map((item) => '${item.quantity}x ${item.productName}')
                  .join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            _buildOrderProgressTimeline(order.status),
            if (!isAdmin &&
                order.paymentMethod.toUpperCase().contains('MIDTRANS') &&
                order.status == 'pending') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onShowMidtransDetails,
                  icon: const Icon(Icons.qr_code_2_rounded, size: 22),
                  label: const Text(
                    'Lihat Kembali VA / QRIS Pembayaran',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            ],
            if (!isAdmin &&
                (order.status == 'pending' || order.status == 'processing')) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  minimumSize: const Size.fromHeight(36),
                ),
                onPressed: onRequestCancellation,
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: Text(
                  order.status == 'processing'
                      ? 'Batalkan Pesanan & Refund'
                      : 'Batalkan Pesanan',
                ),
              ),
            ],
            if (!isAdmin && order.status == 'cancellation_requested') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.refundAccountNumber.isNotEmpty
                          ? 'Permintaan pembatalan & refund sedang menunggu persetujuan admin.'
                          : 'Permintaan pembatalan pesanan sedang menunggu persetujuan admin.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (order.cancellationReason.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Alasan: ${order.cancellationReason}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (isAdmin && order.status == 'cancellation_requested') ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alasan Batal: ${order.cancellationReason.isNotEmpty ? order.cancellationReason : "-"}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    if (order.refundAccountNumber.isNotEmpty)
                      Text(
                        'Rekening Refund: ${order.refundBankName.toUpperCase()} - ${order.refundAccountNumber} a.n. ${order.refundAccountName}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      )
                    else
                      const Text(
                        'Status Pembayaran: Belum Bayar (Tanpa Refund Dana)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onApproveCancellation,
                      child: Text(
                        order.refundAccountNumber.isNotEmpty
                            ? 'Setujui Batal & Refund (IRIS)'
                            : 'Setujui Pembatalan Pesanan',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onRejectCancellation,
                      child: const Text('Tolak Pengajuan'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${order.paymentMethod} · ${moneyFormatter(order.totalCents)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (!isAdmin)
                  TextButton(
                    onPressed: onBuyAgain,
                    child: const Text('Beli lagi'),
                  )
                else
                  PopupMenuButton<String>(
                    tooltip: 'Ubah status pesanan',
                    onSelected: (val) {
                      if (val == 'simulate_payment') {
                        onSimulatePayment();
                      } else {
                        onUpdateStatus(val);
                      }
                    },
                    itemBuilder: (_) => [
                      if (order.paymentMethod.startsWith('MIDTRANS') &&
                          order.status == 'pending')
                        const PopupMenuItem(
                          value: 'simulate_payment',
                          child: Row(
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                size: 18,
                                color: Colors.green,
                              ),
                              SizedBox(width: 8),
                              Text('Simulasi Bayar Lunas'),
                            ],
                          ),
                        ),
                      if (order.status == 'pending')
                        const PopupMenuItem(
                          value: 'processing',
                          child: Row(
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Proses pesanan'),
                            ],
                          ),
                        ),
                      if (order.status == 'pending' ||
                          order.status == 'processing')
                        const PopupMenuItem(
                          value: 'shipping',
                          child: Row(
                            children: [
                              Icon(Icons.local_shipping_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Kirim pesanan (Shipping)'),
                            ],
                          ),
                        ),
                      if (order.status != 'completed' &&
                          order.status != 'cancelled')
                        const PopupMenuItem(
                          value: 'completed',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline, size: 18),
                              SizedBox(width: 8),
                              Text('Pesanan selesai'),
                            ],
                          ),
                        ),
                      if (order.status != 'completed' &&
                          order.status != 'cancelled')
                        const PopupMenuItem(
                          value: 'cancelled',
                          child: Row(
                            children: [
                              Icon(
                                Icons.cancel_outlined,
                                size: 18,
                                color: Colors.red,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Batalkan pesanan',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final (label, color) = switch (status) {
      'pending' => ('Menunggu Pembayaran', AppColors.warning),
      'processing' => ('Diproses', AppColors.warning),
      'shipping' => ('Dikirim', AppColors.primary),
      'completed' => ('Selesai', AppColors.success),
      'cancelled' => ('Dibatalkan', AppColors.error),
      'cancellation_requested' => ('Pengajuan Batal', Colors.deepOrange),
      _ => ('Menunggu Pembayaran', AppColors.textTertiary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.tagAll,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildOrderProgressTimeline(String status) {
    if (status == 'cancelled' || status == 'cancellation_requested') {
      return const SizedBox.shrink();
    }

    int currentStep;
    switch (status) {
      case 'processing':
        currentStep = 1;
        break;
      case 'shipping':
        currentStep = 2;
        break;
      case 'completed':
        currentStep = 3;
        break;
      default:
        currentStep = 0;
    }

    final steps = ['Diterima', 'Diproses', 'Dikirim', 'Selesai'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: AppRadius.cardAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progres Pesanan:',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(steps.length, (index) {
              final isPassed = index <= currentStep;
              final isCurrent = index == currentStep;
              final isLast = index == steps.length - 1;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: isCurrent ? 10 : 8,
                            backgroundColor: isPassed
                                ? (isCurrent ? AppColors.primary : AppColors.success)
                                : AppColors.border,
                            child: Icon(
                              isPassed ? Icons.check : Icons.circle,
                              size: isCurrent ? 11 : 7,
                              color: isPassed ? Colors.white : AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            steps[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isPassed ? AppColors.textPrimary : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index < currentStep ? AppColors.success : AppColors.border,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
