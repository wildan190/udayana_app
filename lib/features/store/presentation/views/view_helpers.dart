import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Ruang bawah untuk halaman ber-scroll agar elemen terakhir bisa digulir
/// melewati floating bottom navbar (liquid glass).
const double kBottomNavInset = 120;

/// Judul section khusus tampilan admin / header umum.
Widget adminHeading(BuildContext context, String title) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );

/// Baris ringkasan (label - nilai).
Widget summaryRow(String label, String value, {bool bold = false}) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: bold ? AppColors.textPrimary : null,
          ),
        ),
      ],
    );

/// Tombol utama selebar layar.
Widget primaryButton({
  required String label,
  required VoidCallback onPressed,
}) =>
    SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(label),
      ),
    );

/// Chip status pesanan dengan indikator warna.
Widget statusChip(String status) {
  final (label, color) = switch (status) {
    'pending' => ('Menunggu Pembayaran', const Color(0xFF9A6900)),
    'processing' => ('Diproses', const Color(0xFF9A6900)),
    'shipping' => ('Dikirim', const Color(0xFF0C6AB2)),
    'completed' => ('Selesai', const Color(0xFF167D62)),
    'cancelled' => ('Dibatalkan', const Color(0xFFB42318)),
    _ => ('Menunggu Pembayaran', const Color(0xFF52606D)),
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: AppRadius.tagAll,
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// Visual metode pembayaran: logo bank bila tersedia, jika tidak pakai ikon.
Widget paymentMethodVisual({
  required IconData icon,
  String? logo,
  double size = 22,
  Color? color,
}) {
  if (logo == null) {
    return Icon(icon, size: size, color: color);
  }
  return Image.asset(
    logo,
    width: size,
    height: size,
    fit: BoxFit.contain,
    errorBuilder: (_, _, _) => Icon(icon, size: size, color: color),
  );
}

/// Panel info kosong (misal keranjang kosong, produk tidak ada).
Widget emptyPanel(String title, String subtitle, IconData icon) => Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.textTertiary),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );

/// Panel error dengan tombol coba lagi.
Widget errorPanel(String error, Future<void> Function() retry) => Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            const Text('Tidak dapat memuat data'),
            const SizedBox(height: 6),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );

/// Kontainer info error inline dalam list/sliver.
Widget inlineError(String message) => Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: AppRadius.controlAll,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.error)),
    );
