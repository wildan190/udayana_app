class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    this.province = '',
    this.city = '',
    this.district = '',
    this.subdistrict = '',
    this.rtRw = '',
    this.postalCode = '',
    this.address = '',
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String phone;
  final String province;
  final String city;
  final String district;
  final String subdistrict;
  final String rtRw;
  final String postalCode;
  final String address;

  bool get isAdmin => role == 'admin';

  bool get hasAddress =>
      province.isNotEmpty ||
      city.isNotEmpty ||
      district.isNotEmpty ||
      address.isNotEmpty;

  String get formattedAddress {
    final parts = <String>[];
    if (address.isNotEmpty) parts.add(address);
    if (rtRw.isNotEmpty) parts.add('RT/RW $rtRw');
    if (subdistrict.isNotEmpty) parts.add('Kel. $subdistrict');
    if (district.isNotEmpty) parts.add('Kec. $district');
    if (city.isNotEmpty) parts.add(city);
    if (province.isNotEmpty) parts.add(province);
    if (postalCode.isNotEmpty) parts.add(postalCode);
    return parts.join(', ');
  }

  AppUser copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? province,
    String? city,
    String? district,
    String? subdistrict,
    String? rtRw,
    String? postalCode,
    String? address,
  }) => AppUser(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    role: role ?? this.role,
    phone: phone ?? this.phone,
    province: province ?? this.province,
    city: city ?? this.city,
    district: district ?? this.district,
    subdistrict: subdistrict ?? this.subdistrict,
    rtRw: rtRw ?? this.rtRw,
    postalCode: postalCode ?? this.postalCode,
    address: address ?? this.address,
  );
}
