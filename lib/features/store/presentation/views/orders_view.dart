import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../orders/domain/entities/order.dart';
import '../../../orders/presentation/state/order_controller.dart';
import '../widgets/order_card.dart';
import '../widgets/skeleton_loader.dart';
import 'view_helpers.dart';

/// Pilihan filter status pesanan (value -> label).
const Map<String, String> orderStatusFilters = {
  'all': 'Semua',
  'pending': 'Belum Bayar',
  'processing': 'Diproses',
  'shipping': 'Dikirim',
  'completed': 'Selesai',
  'cancelled': 'Dibatalkan',
};

class OrdersView extends StatelessWidget {
  const OrdersView({
    super.key,
    required this.ordersController,
    required this.isAdmin,
    required this.orderDateFilter,
    required this.orderStatusFilter,
    required this.customFilterDate,
    required this.onOrderDateFilterChanged,
    required this.onCustomFilterDateSelected,
    required this.onOrderStatusFilterChanged,
    required this.onReloadOrders,
    required this.onShowMidtransDetails,
    required this.onBuyAgain,
    required this.onUpdateStatus,
    required this.onSimulatePayment,
    required this.onRequestCancellation,
    required this.onApproveCancellation,
    required this.onRejectCancellation,
    required this.moneyFormatter,
  });

  final OrderController ordersController;
  final bool isAdmin;
  final String orderDateFilter;
  final String orderStatusFilter;
  final DateTime? customFilterDate;
  final ValueChanged<String> onOrderDateFilterChanged;
  final Function(DateTime?) onCustomFilterDateSelected;
  final ValueChanged<String> onOrderStatusFilterChanged;
  final Future<void> Function() onReloadOrders;
  final Function(Order) onShowMidtransDetails;
  final Function(Order) onBuyAgain;
  final Function(int orderId, String status) onUpdateStatus;
  final Function(Order) onSimulatePayment;
  final Function(int orderId, String status) onRequestCancellation;
  final Function(int orderId) onApproveCancellation;
  final Function(int orderId) onRejectCancellation;
  final String Function(int) moneyFormatter;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ordersController,
      builder: (context, _) {
        final state = ordersController.state;
        if (state.isLoading && state.orders.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(18),
            children: const [
              OrderCardSkeleton(),
              OrderCardSkeleton(),
              OrderCardSkeleton(),
            ],
          );
        }
        if (state.error != null && state.orders.isEmpty) {
          return emptyPanel(
            'Belum ada pesanan',
            'Pesanan yang dibuat akan tampil di sini.',
            Icons.receipt_long_outlined,
          );
        }

        final now = DateTime.now();
        final visibleOrders = state.orders.where((order) {
          if (orderStatusFilter != 'all' &&
              order.status != orderStatusFilter) {
            return false;
          }
          if (orderDateFilter == 'today') {
            return order.createdAt.year == now.year &&
                order.createdAt.month == now.month &&
                order.createdAt.day == now.day;
          }
          if (orderDateFilter == 'month') {
            return order.createdAt.year == now.year &&
                order.createdAt.month == now.month;
          }
          if (orderDateFilter == 'year') {
            return order.createdAt.year == now.year;
          }
          if (orderDateFilter == 'custom' && customFilterDate != null) {
            return order.createdAt.year == customFilterDate!.year &&
                order.createdAt.month == customFilterDate!.month &&
                order.createdAt.day == customFilterDate!.day;
          }
          return true;
        }).toList();

        return RefreshIndicator(
          onRefresh: onReloadOrders,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              adminHeading(context, isAdmin ? 'Kelola pesanan' : 'Pesanan saya'),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: orderDateFilter,
                decoration: const InputDecoration(
                  labelText: 'Filter Berdasarkan Tanggal',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('Semua Tanggal'),
                  ),
                  const DropdownMenuItem(
                    value: 'today',
                    child: Text('Hari Ini'),
                  ),
                  const DropdownMenuItem(
                    value: 'month',
                    child: Text('Bulan Ini'),
                  ),
                  const DropdownMenuItem(
                    value: 'year',
                    child: Text('Tahun Ini'),
                  ),
                  DropdownMenuItem(
                    value: 'custom',
                    child: Text(
                      customFilterDate != null
                          ? 'Pilih: ${DateFormat('dd MMM yyyy').format(customFilterDate!)}'
                          : 'Pilih Tanggal Khusus...',
                    ),
                  ),
                ],
                onChanged: (value) async {
                  if (value == null) return;
                  if (value == 'custom') {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: customFilterDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      onCustomFilterDateSelected(picked);
                    }
                  } else {
                    onOrderDateFilterChanged(value);
                  }
                },
              ),
              const SizedBox(height: 12),
              _orderStatusChips(),
              const SizedBox(height: 14),
              if (state.error != null) inlineError(state.error!),
              if (visibleOrders.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(
                    child: Text('Tidak ada pesanan untuk filter ini.'),
                  ),
                )
              else
                for (final order in visibleOrders)
                  OrderCard(
                    order: order,
                    isAdmin: isAdmin,
                    moneyFormatter: moneyFormatter,
                    onShowMidtransDetails: () => onShowMidtransDetails(order),
                    onBuyAgain: () => onBuyAgain(order),
                    onUpdateStatus: (val) => onUpdateStatus(order.id, val),
                    onSimulatePayment: () => onSimulatePayment(order),
                    onRequestCancellation: () =>
                        onRequestCancellation(order.id, order.status),
                    onApproveCancellation: () =>
                        onApproveCancellation(order.id),
                    onRejectCancellation: () => onRejectCancellation(order.id),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _orderStatusChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in orderStatusFilters.entries) ...[
            ChoiceChip(
              label: Text(entry.value),
              selected: orderStatusFilter == entry.key,
              onSelected: (_) => onOrderStatusFilterChanged(entry.key),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
