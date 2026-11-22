import 'package:flutter/material.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 12,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AspectRatio(
              aspectRatio: 1.0,
              child: SkeletonBox(borderRadius: 15),
            ),
            const SizedBox(height: 10),
            const SkeletonBox(width: 60, height: 10),
            const SizedBox(height: 6),
            const SkeletonBox(width: double.infinity, height: 14),
            const SizedBox(height: 6),
            const SkeletonBox(width: 80, height: 14),
            const SizedBox(height: 10),
            const SkeletonBox(width: double.infinity, height: 36, borderRadius: 16),
          ],
        ),
      ),
    );
  }
}

class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 13,
        crossAxisSpacing: 13,
        mainAxisExtent: 335,
      ),
      itemBuilder: (context, index) => const ProductCardSkeleton(),
    );
  }
}

class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 120, height: 16),
                SkeletonBox(width: 80, height: 24, borderRadius: 12),
              ],
            ),
            SizedBox(height: 14),
            SkeletonBox(width: double.infinity, height: 14),
            SizedBox(height: 8),
            SkeletonBox(width: 180, height: 14),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 100, height: 18),
                SkeletonBox(width: 90, height: 36, borderRadius: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
