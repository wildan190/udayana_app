class UserModel {
  const UserModel({
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
    this.is2FAEnabled = false,
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
  final bool is2FAEnabled;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    role: json['role'] as String? ?? 'buyer',
    phone: json['phone'] as String? ?? '',
    province: json['province'] as String? ?? '',
    city: json['city'] as String? ?? '',
    district: json['district'] as String? ?? '',
    subdistrict: json['subdistrict'] as String? ?? '',
    rtRw: json['rt_rw'] as String? ?? '',
    postalCode: json['postal_code'] as String? ?? '',
    address: json['address'] as String? ?? '',
    is2FAEnabled: json['is_2fa_enabled'] as bool? ?? false,
  );
}
