import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../products/domain/entities/product.dart';
import '../widgets/product_card.dart';
import 'view_helpers.dart';

class AccountView extends StatelessWidget {
  const AccountView({
    super.key,
    required this.user,
    required this.orders,
    required this.recentlyViewed,
    required this.cart,
    required this.isAdmin,
    required this.onOpenProfile,
    required this.onOpenAddressSelectionDialog,
    required this.onOpenOrdersWithStatus,
    required this.onOpenProductDetail,
    required this.onShowProductForm,
    required this.onRemoveProduct,
    required this.onAddToCart,
    required this.onSignOut,
    required this.resolvedImageUrl,
    required this.moneyFormatter,
  });

  final AppUser user;
  final List<Order> orders;
  final List<Product> recentlyViewed;
  final Map<int, int> cart;
  final bool isAdmin;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenAddressSelectionDialog;
  final ValueChanged<String> onOpenOrdersWithStatus;
  final Function(Product) onOpenProductDetail;
  final Function([Product?]) onShowProductForm;
  final Function(Product) onRemoveProduct;
  final Function(Product) onAddToCart;
  final VoidCallback onSignOut;
  final String Function(String) resolvedImageUrl;
  final String Function(int) moneyFormatter;

  @override
  Widget build(BuildContext context) {
    final userOrders = orders;

    final totalSpentCents = userOrders
        .where((o) => o.status != 'cancelled')
        .fold<int>(0, (sum, o) => sum + o.totalCents);

    final pendingCount =
        userOrders.where((o) => o.status == 'pending').length;
    final processingCount =
        userOrders.where((o) => o.status == 'processing').length;
    final shippingCount =
        userOrders.where((o) => o.status == 'shipping').length;
    final completedCount =
        userOrders.where((o) => o.status == 'completed').length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30 + kBottomNavInset),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryBg,
                  child: Text(
                    user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      if (user.phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.phone,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit Profil',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onOpenProfile,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          color: AppColors.primaryBg,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Total Pengeluaran',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  moneyFormatter(totalSpentCents),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Total akumulasi belanja Anda di Udayana Market.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Status Transaksi Saya',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statusShortcutCard(
                'Belum Bayar',
                pendingCount,
                Icons.hourglass_top_rounded,
                AppColors.warning,
                () => onOpenOrdersWithStatus('pending'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statusShortcutCard(
                'Dipproses',
                processingCount,
                Icons.inventory_2_outlined,
                AppColors.primary,
                () => onOpenOrdersWithStatus('processing'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _statusShortcutCard(
                'Dikirim',
                shippingCount,
                Icons.local_shipping_outlined,
                AppColors.primary,
                () => onOpenOrdersWithStatus('shipping'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statusShortcutCard(
                'Selesai',
                completedCount,
                Icons.check_circle_outline,
                AppColors.success,
                () => onOpenOrdersWithStatus('completed'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: const Text('Profil Saya'),
                subtitle: const Text('Ubah nama, email, dan kata sandi'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: onOpenProfile,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Alamat Pengiriman Saya'),
                subtitle: const Text('Kelola dan pilih alamat pengiriman'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: onOpenAddressSelectionDialog,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Baru Saja Dilihat',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (recentlyViewed.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Belum ada produk yang baru saja dilihat.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 275,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recentlyViewed.length,
              itemBuilder: (context, index) => SizedBox(
                width: 170,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ProductCard(
                    product: recentlyViewed[index],
                    quantity: cart[recentlyViewed[index].id] ?? 0,
                    isAdmin: isAdmin,
                    onTap: () => onOpenProductDetail(recentlyViewed[index]),
                    onEdit: () => onShowProductForm(recentlyViewed[index]),
                    onDelete: () => onRemoveProduct(recentlyViewed[index]),
                    onAddToCart: () => onAddToCart(recentlyViewed[index]),
                    resolvedImageUrl: resolvedImageUrl,
                    moneyFormatter: moneyFormatter,
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: onSignOut,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Keluar dari Akun'),
        ),
      ],
    );
  }

  Widget _statusShortcutCard(
    String title,
    int count,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        borderRadius: AppRadius.cardAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: AppRadius.tagAll,
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: color,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
