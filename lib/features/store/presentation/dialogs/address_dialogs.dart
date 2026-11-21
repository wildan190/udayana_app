import 'package:flutter/material.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../../core/di/app_services.dart';

class AddressDialogs {
  static Future<void> showAddressSelectionDialog({
    required BuildContext context,
    required AppServices services,
    required AppUser user,
    required bool isGuest,
    required Future<bool> Function() openLogin,
    required void Function(String) showMessage,
    required ValueChanged<String> onAddressSelected,
  }) async {
    if (isGuest) {
      showMessage('Silakan masuk atau daftar terlebih dahulu.');
      if (await openLogin() && context.mounted) {
        await showAddressSelectionDialog(
          context: context,
          services: services,
          user: user,
          isGuest: false,
          openLogin: openLogin,
          showMessage: showMessage,
          onAddressSelected: onAddressSelected,
        );
      }
      return;
    }

    try {
      List<Map<String, dynamic>> addresses = [];
      try {
        final rawList = await services.listAddresses();
        addresses = rawList.map((item) => item as Map<String, dynamic>).toList();
      } catch (_) {
        if (user.hasAddress) {
          addresses = [
            {
              'id': 0,
              'label': 'Utama (Profil)',
              'recipient_name': user.name,
              'phone': user.phone,
              'address': user.address,
              'province': user.province,
              'city': user.city,
              'district': user.district,
              'subdistrict': user.subdistrict,
              'rt_rw': user.rtRw,
              'postal_code': user.postalCode,
              'is_default': true,
            }
          ];
        }
      }
      if (!context.mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'Pilih Alamat Pengiriman',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await showAddAddressDialog(
                            context: context,
                            services: services,
                            user: user,
                            showMessage: showMessage,
                          );
                          if (context.mounted) {
                            await showAddressSelectionDialog(
                              context: context,
                              services: services,
                              user: user,
                              isGuest: isGuest,
                              openLogin: openLogin,
                              showMessage: showMessage,
                              onAddressSelected: onAddressSelected,
                            );
                          }
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Tambah Alamat'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (addresses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Belum ada alamat tersimpan. Silakan tambah alamat baru.',
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 320,
                      child: ListView.builder(
                        itemCount: addresses.length,
                        itemBuilder: (context, index) {
                          final addr = addresses[index];
                          final fullAddr = [
                            addr['address'],
                            if (addr['rt_rw'] != null &&
                                addr['rt_rw'].toString().isNotEmpty)
                              'RT/RW ${addr['rt_rw']}',
                            if (addr['subdistrict'] != null &&
                                addr['subdistrict'].toString().isNotEmpty)
                              'Kel. ${addr['subdistrict']}',
                            if (addr['district'] != null &&
                                addr['district'].toString().isNotEmpty)
                              'Kec. ${addr['district']}',
                            addr['city'],
                            addr['province'],
                            addr['postal_code'],
                          ]
                              .where(
                                (s) => s != null && s.toString().isNotEmpty,
                              )
                              .join(', ');

                          final isDefault = addr['is_default'] == true;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Text(
                                    addr['label'] ?? 'Rumah',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (isDefault) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Utama',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${addr['recipient_name']} (${addr['phone']})',
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    fullAddr,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      final selected = '$fullAddr [Penerima: ${addr['recipient_name']} - ${addr['phone']}]';
                                      onAddressSelected(selected);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Pilih'),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (val) async {
                                      if (val == 'default') {
                                        await services.setDefaultAddress(
                                          addr['id'] as int,
                                        );
                                        Navigator.pop(context);
                                        if (context.mounted) {
                                          await showAddressSelectionDialog(
                                            context: context,
                                            services: services,
                                            user: user,
                                            isGuest: isGuest,
                                            openLogin: openLogin,
                                            showMessage: showMessage,
                                            onAddressSelected: onAddressSelected,
                                          );
                                        }
                                      } else if (val == 'delete') {
                                        await services.deleteAddress(
                                          addr['id'] as int,
                                        );
                                        Navigator.pop(context);
                                        if (context.mounted) {
                                          await showAddressSelectionDialog(
                                            context: context,
                                            services: services,
                                            user: user,
                                            isGuest: isGuest,
                                            openLogin: openLogin,
                                            showMessage: showMessage,
                                            onAddressSelected: onAddressSelected,
                                          );
                                        }
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      if (!isDefault)
                                        const PopupMenuItem(
                                          value: 'default',
                                          child: Text('Jadikan Utama'),
                                        ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Hapus Alamat'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    } on Exception catch (error) {
      if (context.mounted) showMessage(error.toString());
    }
  }

  static Future<void> showAddAddressDialog({
    required BuildContext context,
    required AppServices services,
    required AppUser user,
    required void Function(String) showMessage,
  }) async {
    final formKey = GlobalKey<FormState>();
    final label = TextEditingController(text: 'Rumah');
    final recipient = TextEditingController(text: user.name);
    final phone = TextEditingController(text: user.phone);
    final province = TextEditingController(text: user.province);
    final city = TextEditingController(text: user.city);
    final district = TextEditingController(text: user.district);
    final subdistrict = TextEditingController(text: user.subdistrict);
    final rtRw = TextEditingController(text: user.rtRw);
    final postalCode = TextEditingController(text: user.postalCode);
    final address = TextEditingController(text: user.address);
    bool isDefault = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                    'Tambah Alamat Baru',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  _buildFormField(label, 'Label Alamat (Contoh: Rumah, Kantor)'),
                  Row(
                    children: [
                      Expanded(child: _buildFormField(recipient, 'Nama Penerima')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildFormField(phone, 'Nomor HP')),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _buildFormField(province, 'Provinsi')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildFormField(city, 'Kota / Kabupaten')),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _buildFormField(district, 'Kecamatan')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildFormField(subdistrict, 'Kelurahan')),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _buildFormField(rtRw, 'RT/RW')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildFormField(postalCode, 'Kode Pos')),
                    ],
                  ),
                  _buildFormField(
                    address,
                    'Alamat Lengkap (Jalan, No. Rumah)',
                    maxLines: 2,
                  ),
                  CheckboxListTile(
                    value: isDefault,
                    onChanged: (val) {
                      if (val != null) setModalState(() => isDefault = val);
                    },
                    title: const Text('Jadikan sebagai alamat utama'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(context, true);
                      }
                    },
                    child: const Text('Simpan Alamat'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (saved != true || !context.mounted) return;

    try {
      await services.createAddress({
        'label': label.text.trim(),
        'recipient_name': recipient.text.trim(),
        'phone': phone.text.trim(),
        'province': province.text.trim(),
        'city': city.text.trim(),
        'district': district.text.trim(),
        'subdistrict': subdistrict.text.trim(),
        'rt_rw': rtRw.text.trim(),
        'postal_code': postalCode.text.trim(),
        'address': address.text.trim(),
        'is_default': isDefault,
      });
      showMessage('Alamat baru berhasil ditambahkan.');
    } on Exception catch (error) {
      if (context.mounted) showMessage(error.toString());
    }
  }

  static Widget _buildFormField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
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
        return null;
      },
    ),
  );
}
