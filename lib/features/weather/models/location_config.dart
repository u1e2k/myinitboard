class LocationConfig {
  final String id;
  final String name; // Custom display name (e.g. "自宅", "職場", "実家")
  final String placeName; // Official place name (e.g. "東京都 千代田区")
  final double lat;
  final double lon;

  const LocationConfig({
    required this.id,
    required this.name,
    this.placeName = '',
    required this.lat,
    required this.lon,
  });

  LocationConfig copyWith({
    String? id,
    String? name,
    String? placeName,
    double? lat,
    double? lon,
  }) {
    return LocationConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      placeName: placeName ?? this.placeName,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'placeName': placeName,
    'lat': lat,
    'lon': lon,
  };

  factory LocationConfig.fromJson(Map<String, dynamic> json) {
    return LocationConfig(
      id: json['id'] as String? ?? 'loc_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? '未設定',
      placeName: json['placeName'] as String? ?? (json['name'] as String? ?? ''),
      lat: (json['lat'] as num?)?.toDouble() ?? 35.6895,
      lon: (json['lon'] as num?)?.toDouble() ?? 139.6917,
    );
  }
}
