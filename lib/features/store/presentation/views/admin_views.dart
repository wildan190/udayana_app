import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/entities/shipping.dart';
import '../widgets/skeleton_loader.dart';
import 'view_helpers.dart';

/// Tab Admin 1: Pelanggan (CustomersView)
class CustomersView extends StatelessWidget {
  const CustomersView({
    super.key,
    required this.panelLoading,
    required this.panelError,
    required this.customers,
    required this.onLoadCustomers,
    required this.onEditCustomer,
  });

  final bool panelLoading;
  final String? panelError;
  final List<Customer> customers;
  final Future<void> Function() onLoadCustomers;
  final Function(Customer) onEditCustomer;

  @override
  Widget build(BuildContext context) {
    if (panelLoading && customers.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(18),
        children: const [
          SkeletonBox(height: 70, borderRadius: 16),
          SizedBox(height: 10),
          SkeletonBox(height: 70, borderRadius: 16),
          SizedBox(height: 10),
          SkeletonBox(height: 70, borderRadius: 16),
        ],
      );
    }
    if (panelError != null && customers.isEmpty) {
      return errorPanel(panelError!, onLoadCustomers);
    }
    return RefreshIndicator(
      onRefresh: onLoadCustomers,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          adminHeading(context, 'Pelanggan'),
          if (panelError != null) inlineError(panelError!),
          if (customers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Text('Belum ada pelanggan terdaftar.'),
            ),
          for (final customer in customers)
            Card(
              margin: const EdgeInsets.only(bottom: 9),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(customer.name.isEmpty ? '?' : customer.name[0]),
                ),
                title: Text(customer.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        customer.email,
                        customer.phone,
                      ].where((item) => item.isNotEmpty).join(' · '),
                    ),
                    if (customer.formattedAddress.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Alamat: ${customer.formattedAddress}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: IconButton(
                  tooltip: 'Edit pelanggan & alamat',
                  onPressed: () => onEditCustomer(customer),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tab Admin 2: Laporan Penjualan (ReportsView)
class ReportsView extends StatelessWidget {
  const ReportsView({
    super.key,
    required this.panelLoading,
    required this.panelError,
    required this.reportPeriod,
    required this.reportValue,
    required this.report,
    required this.onPeriodChanged,
    required this.onReportValueChanged,
    required this.onChooseReportMonth,
    required this.onLoadReport,
    required this.onOpenWithdrawDialog,
    required this.moneyFormatter,
  });

  final bool panelLoading;
  final String? panelError;
  final String reportPeriod;
  final String reportValue;
  final SalesReport? report;
  final ValueChanged<String> onPeriodChanged;
  final ValueChanged<String> onReportValueChanged;
  final VoidCallback onChooseReportMonth;
  final Future<void> Function() onLoadReport;
  final VoidCallback onOpenWithdrawDialog;
  final String Function(int) moneyFormatter;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        adminHeading(context, 'Ringkasan penjualan'),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'month', label: Text('Bulanan')),
            ButtonSegment(value: 'year', label: Text('Tahunan')),
          ],
          selected: {reportPeriod},
          onSelectionChanged: (selection) => onPeriodChanged(selection.first),
        ),
        const SizedBox(height: 14),
        if (reportPeriod == 'month')
          OutlinedButton.icon(
            onPressed: onChooseReportMonth,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(reportValue),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: reportValue,
            decoration: const InputDecoration(labelText: 'Tahun laporan'),
            items: [
              for (
                var year = DateTime.now().year;
                year >= DateTime.now().year - 4;
                year--
              )
                DropdownMenuItem(value: '$year', child: Text('$year')),
            ],
            onChanged: (value) {
              if (value != null) onReportValueChanged(value);
            },
          ),
        const SizedBox(height: 14),
        if (panelLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (panelError != null)
          inlineError(panelError!)
        else if (report != null) ...[
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  context,
                  'Saldo Midtrans',
                  moneyFormatter(report!.midtransRevenueCents),
                  Icons.account_balance_wallet_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricCard(
                  context,
                  'Penjualan COD',
                  moneyFormatter(report!.codRevenueCents),
                  Icons.payments_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  context,
                  'Omzet Total',
                  moneyFormatter(report!.revenueCents),
                  Icons.monetization_on_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricCard(
                  context,
                  'Total Pesanan',
                  '${report!.orderCount}',
                  Icons.receipt_long_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _reportCard(
            title: 'Kategori paling sering dibeli',
            rows: report!.topCategories,
          ),
          const SizedBox(height: 12),
          _reportCard(
            title: 'Kebutuhan pelanggan',
            rows: report!.needTypeTotals.map((row) {
              final label = row.label == 'daily_need'
                  ? 'Daily need'
                  : 'Daily essentials';
              return ReportRow(label: label, quantity: row.quantity);
            }).toList(),
          ),
          const SizedBox(height: 20),
          Card(
            color: AppColors.primaryBg,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Penarikan Dana (Withdraw Iris)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tarik saldo hasil penjualan Midtrans langsung ke rekening bank Anda.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: onOpenWithdrawDialog,
                    icon: const Icon(Icons.account_balance_rounded),
                    label: const Text('Input Rekening & Tarik Dana'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _metricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                value,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
        ),
      );

  Widget _reportCard({
    required String title,
    required List<ReportRow> rows,
  }) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              if (rows.isEmpty) const Text('Belum ada data pada periode ini.'),
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Expanded(child: Text(row.label)),
                      Text(
                        '${row.quantity} item',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
}

/// Tab Admin 3: Pengaturan Ongkir (ShippingAdminView)
class ShippingAdminView extends StatelessWidget {
  const ShippingAdminView({
    super.key,
    required this.panelLoading,
    required this.panelError,
    required this.shippingConfig,
    required this.onLoadShippingConfig,
    required this.onEditShippingSettings,
    required this.onEditShippingZone,
    required this.onDeleteShippingZone,
    required this.onEditShippingArea,
    required this.onDeleteShippingArea,
    required this.moneyFormatter,
  });

  final bool panelLoading;
  final String? panelError;
  final ShippingConfig? shippingConfig;
  final Future<void> Function() onLoadShippingConfig;
  final VoidCallback onEditShippingSettings;
  final Function([ShippingZone?]) onEditShippingZone;
  final Function(ShippingZone) onDeleteShippingZone;
  final Function([ShippingArea?]) onEditShippingArea;
  final Function(ShippingArea) onDeleteShippingArea;
  final String Function(int) moneyFormatter;

  @override
  Widget build(BuildContext context) {
    final config = shippingConfig;
    if (panelLoading && config == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (panelError != null && config == null) {
      return errorPanel(panelError!, onLoadShippingConfig);
    }
    return RefreshIndicator(
      onRefresh: onLoadShippingConfig,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        children: [
          adminHeading(context, 'Ongkos kirim'),
          if (panelError != null) inlineError(panelError!),
          _shippingSettingsCard(config?.settings ?? const ShippingSettings()),
          const SizedBox(height: 16),
          _shippingZonesCard(config?.zones ?? const []),
          const SizedBox(height: 16),
          _shippingAreasCard(config?.areas ?? const []),
        ],
      ),
    );
  }

  Widget _shippingSectionCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
    Widget? action,
  }) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (action != null) action,
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      );

  Widget _shippingSettingsCard(ShippingSettings settings) =>
      _shippingSectionCard(
        title: 'Titik asal & tarif bawaan',
        subtitle:
            'Tarif bawaan dipakai bila wilayah tujuan belum terdaftar. Koordinat toko hanya perlu diisi kalau mau pakai zona jarak.',
        action: IconButton(
          tooltip: 'Ubah pengaturan',
          onPressed: onEditShippingSettings,
          icon: const Icon(Icons.edit_outlined),
        ),
        children: [
          _shippingInfoRow(
            'Koordinat asal',
            settings.originLatitude == 0 && settings.originLongitude == 0
                ? 'Belum diatur'
                : '${settings.originLatitude}, ${settings.originLongitude}',
          ),
          const SizedBox(height: 6),
          _shippingInfoRow(
            'Tarif bawaan',
            moneyFormatter(settings.defaultFeeCents),
          ),
        ],
      );

  Widget _shippingZonesCard(List<ShippingZone> zones) => _shippingSectionCard(
        title: 'Zona jarak (opsional)',
        subtitle:
            'Tarif tetap per rentang jarak (km). Boleh dilewati jika cukup memakai tarif per wilayah.',
        action: TextButton.icon(
          onPressed: () => onEditShippingZone(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tambah'),
        ),
        children: [
          if (zones.isEmpty)
            const Text('Belum ada zona. Ongkir memakai tarif bawaan.')
          else
            for (final zone in zones)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            zone.name.isEmpty
                                ? '${zone.minKm.toStringAsFixed(0)} - ${zone.maxKm.toStringAsFixed(0)} km'
                                : zone.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${zone.minKm.toStringAsFixed(1)} - ${zone.maxKm.toStringAsFixed(1)} km · ${moneyFormatter(zone.feeCents)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ubah zona',
                      onPressed: () => onEditShippingZone(zone),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Hapus zona',
                      onPressed: () => onDeleteShippingZone(zone),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
        ],
      );

  Widget _shippingAreasCard(List<ShippingArea> areas) => _shippingSectionCard(
        title: 'Wilayah tujuan',
        subtitle:
            'Cukup isi kota/kecamatan dan tarif ongkirnya — tanpa perlu koordinat. Sistem mencocokkan kota & kecamatan yang dipilih pembeli.',
        action: TextButton.icon(
          onPressed: () => onEditShippingArea(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tambah'),
        ),
        children: [
          if (areas.isEmpty)
            const Text(
              'Belum ada wilayah. Tambahkan kota/kecamatan beserta tarif ongkirnya.',
            )
          else
            for (final area in areas)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            area.district.isEmpty
                                ? area.city
                                : '${area.district}, ${area.city}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            area.feeCents > 0
                                ? 'Tarif ${moneyFormatter(area.feeCents)}'
                                : 'Tarif belum diatur',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ubah wilayah',
                      onPressed: () => onEditShippingArea(area),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Hapus wilayah',
                      onPressed: () => onDeleteShippingArea(area),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
        ],
      );

  Widget _shippingInfoRow(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      );
}
