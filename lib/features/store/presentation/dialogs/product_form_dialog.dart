import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/state/product_controller.dart';
import '../../../products/presentation/state/product_event.dart';

class ProductFormDialog {
  static Future<void> show({
    required BuildContext context,
    Product? product,
    required ProductController productsController,
    required String Function(String) resolvedImageUrl,
    required void Function(String) showMessage,
  }) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: product?.name ?? '');
    final description = TextEditingController(text: product?.description ?? '');
    final categories = [
      'Bahan Pokok',
      'Makanan',
      'Minuman',
      'Protein',
      'Perawatan Diri',
      'Rumah Tangga',
      'Lainnya',
    ];
    var selectedCategory = categories.contains(product?.category)
        ? product!.category
        : categories.first;
    if (product != null &&
        product.category.isNotEmpty &&
        !categories.contains(product.category)) {
      categories.add(product.category);
      selectedCategory = product.category;
    }
    final priceInRupiah = product == null ? 0.0 : product.priceCents / 100;
    final price = TextEditingController(
      text: product == null
          ? ''
          : priceInRupiah.toStringAsFixed(
              priceInRupiah.truncateToDouble() == priceInRupiah ? 0 : 2,
            ),
    );
    final stock = TextEditingController(text: product?.stock.toString() ?? '');
    var needType = product?.needType ?? 'daily_need';
    var imageUrl = product?.imageUrl ?? '';
    XFile? selectedImage;
    Uint8List? selectedImageBytes;
    var isSaving = false;

    final saved = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            widthFactor: 1,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 620,
                maxHeight: MediaQuery.sizeOf(context).height * .88,
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
                        product == null ? 'Tambah produk' : 'Edit produk',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 18),
                      _buildFormField(name, 'Nama produk'),
                      _buildFormField(description, 'Deskripsi'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategori Produk',
                        ),
                        items: categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildFormField(
                        price,
                        'Harga (rupiah)',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        allowDecimal: true,
                      ),
                      _buildFormField(
                        stock,
                        'Stok',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () async {
                                try {
                                  final image = await ImagePicker().pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 85,
                                    maxWidth: 1600,
                                    maxHeight: 1600,
                                  );
                                  if (image == null) return;
                                  final bytes = await image.readAsBytes();
                                  if (!context.mounted) return;
                                  if (bytes.length > 10 * 1024 * 1024) {
                                    showMessage('Ukuran foto maksimal 10 MB.');
                                    return;
                                  }
                                  setSheetState(() {
                                    selectedImage = image;
                                    selectedImageBytes = bytes;
                                  });
                                } on Exception catch (error) {
                                  if (context.mounted) {
                                    showMessage(
                                      'Foto tidak dapat dipilih: $error',
                                    );
                                  }
                                }
                              },
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(
                          selectedImage == null
                              ? 'Pilih foto produk'
                              : 'Ganti foto produk',
                        ),
                      ),
                      if (selectedImageBytes != null ||
                          imageUrl.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: AspectRatio(
                            aspectRatio: 2,
                            child: selectedImageBytes != null
                                ? Image.memory(
                                    selectedImageBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    resolvedImageUrl(imageUrl),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Center(
                                      child: Icon(Icons.broken_image_outlined),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: needType,
                        decoration: const InputDecoration(
                          labelText: 'Jenis kebutuhan',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'daily_need',
                            child: Text('Daily need'),
                          ),
                          DropdownMenuItem(
                            value: 'daily_essentials',
                            child: Text('Daily essentials'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setSheetState(() => needType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isSaving
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('Batal'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    setSheetState(() => isSaving = true);
                                    try {
                                      if (selectedImage != null &&
                                          selectedImageBytes != null) {
                                        try {
                                          imageUrl = await productsController.uploadImage(
                                            selectedImage!.name,
                                            selectedImageBytes!,
                                          );
                                        } catch (_) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Gagal unggah foto ke S3. Menyimpan produk tanpa foto.',
                                                ),
                                              ),
                                            );
                                          }
                                          imageUrl = product?.imageUrl ?? '';
                                        }
                                      }
                                      if (!context.mounted) return;
                                      final priceCents =
                                          (double.parse(price.text.trim()) *
                                                  100)
                                              .round();
                                      final stockValue = int.parse(
                                        stock.text.trim(),
                                      );
                                      Navigator.pop(
                                        context,
                                        Product(
                                          id: product?.id ?? 0,
                                          name: name.text.trim(),
                                          description: description.text.trim(),
                                          category: selectedCategory,
                                          needType: needType,
                                          priceCents: priceCents,
                                          stock: stockValue,
                                          imageUrl: imageUrl,
                                          active: true,
                                        ),
                                      );
                                    } on Exception catch (error) {
                                      if (context.mounted) {
                                        setSheetState(() => isSaving = false);
                                        showMessage(error.toString());
                                      }
                                    }
                                  },
                            child: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Simpan'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    name.dispose();
    description.dispose();
    price.dispose();
    stock.dispose();
    if (saved == null || !context.mounted) return;
    await productsController.dispatch(ProductSaveRequested(saved, id: product?.id));
    if (productsController.state.error != null) {
      showMessage(productsController.state.error!);
    }
  }

  static Widget _buildFormField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    bool allowDecimal = false,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Wajib diisi';
        if (keyboardType != null) {
          final parsed = allowDecimal
              ? double.tryParse(value.trim())
              : int.tryParse(value.trim());
          if (parsed == null || parsed < 0) return 'Masukkan angka valid';
        }
        return null;
      },
    ),
  );
}
