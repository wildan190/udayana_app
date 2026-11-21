/// Hasil perhitungan ongkos kirim untuk satu alamat tujuan.
class ShippingQuote {
  const ShippingQuote({
    this.city = '',
    this.district = '',
    this.distanceKm = 0,
    this.feeCents = 0,
    this.inCoverage = false,
  });

  final String city;
  final String district;
  final double distanceKm;
  final int feeCents;

  /// True bila wilayah tujuan terdaftar dan ongkir diambil dari zona jarak.
  final bool inCoverage;

  factory ShippingQuote.fromJson(Map<String, dynamic> json) => ShippingQuote(
    city: json['city'] as String? ?? '',
    district: json['district'] as String? ?? '',
    distanceKm: (json['distance_km'] as num? ?? 0).toDouble(),
    feeCents: (json['fee_cents'] as num? ?? 0).toInt(),
    inCoverage: json['in_coverage'] as bool? ?? false,
  );
}

/// Titik asal pengiriman dan ongkos kirim bawaan.
class ShippingSettings {
  const ShippingSettings({
    this.originLatitude = 0,
    this.originLongitude = 0,
    this.defaultFeeCents = 1000000,
  });

  final double originLatitude;
  final double originLongitude;
  final int defaultFeeCents;

  factory ShippingSettings.fromJson(Map<String, dynamic> json) =>
      ShippingSettings(
        originLatitude: (json['origin_latitude'] as num? ?? 0).toDouble(),
        originLongitude: (json['origin_longitude'] as num? ?? 0).toDouble(),
        defaultFeeCents: (json['default_fee_cents'] as num? ?? 1000000).toInt(),
      );

  Map<String, dynamic> toJson() => {
    'origin_latitude': originLatitude,
    'origin_longitude': originLongitude,
    'default_fee_cents': defaultFeeCents,
  };
}

/// Zona jarak: rentang km dengan tarif tetap.
class ShippingZone {
  const ShippingZone({
    this.id = 0,
    this.name = '',
    this.minKm = 0,
    this.maxKm = 0,
    this.feeCents = 0,
  });

  final int id;
  final String name;
  final double minKm;
  final double maxKm;
  final int feeCents;

  factory ShippingZone.fromJson(Map<String, dynamic> json) => ShippingZone(
    id: (json['id'] as num? ?? 0).toInt(),
    name: json['name'] as String? ?? '',
    minKm: (json['min_km'] as num? ?? 0).toDouble(),
    maxKm: (json['max_km'] as num? ?? 0).toDouble(),
    feeCents: (json['fee_cents'] as num? ?? 0).toInt(),
  );
}

/// Wilayah tujuan beserta tarifnya. Tarif bisa diisi langsung tanpa koordinat;
/// koordinat hanya diperlukan bila memakai mode zona jarak.
class ShippingArea {
  const ShippingArea({
    this.id = 0,
    this.city = '',
    this.district = '',
    this.feeCents = 0,
    this.latitude = 0,
    this.longitude = 0,
  });

  final int id;
  final String city;
  final String district;
  final int feeCents;
  final double latitude;
  final double longitude;

  factory ShippingArea.fromJson(Map<String, dynamic> json) => ShippingArea(
    id: (json['id'] as num? ?? 0).toInt(),
    city: json['city'] as String? ?? '',
    district: json['district'] as String? ?? '',
    feeCents: (json['fee_cents'] as num? ?? 0).toInt(),
    latitude: (json['latitude'] as num? ?? 0).toDouble(),
    longitude: (json['longitude'] as num? ?? 0).toDouble(),
  );
}

/// Konfigurasi ongkos kirim lengkap yang dikelola admin.
class ShippingConfig {
  const ShippingConfig({
    this.settings = const ShippingSettings(),
    this.zones = const [],
    this.areas = const [],
  });

  final ShippingSettings settings;
  final List<ShippingZone> zones;
  final List<ShippingArea> areas;

  factory ShippingConfig.fromJson(Map<String, dynamic> json) => ShippingConfig(
    settings: ShippingSettings.fromJson(
      json['settings'] as Map<String, dynamic>? ?? const {},
    ),
    zones: (json['zones'] as List<dynamic>? ?? const [])
        .map((item) => ShippingZone.fromJson(item as Map<String, dynamic>))
        .toList(),
    areas: (json['areas'] as List<dynamic>? ?? const [])
        .map((item) => ShippingArea.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}
