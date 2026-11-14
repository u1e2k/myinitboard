class LocationConfig {
  final String id; // 'left' or 'right'
  final String name;
  final double lat;
  final double lon;

  const LocationConfig({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
  });

  LocationConfig copyWith({
    String? id,
    String? name,
    double? lat,
    double? lon,
  }) {
    return LocationConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'lat': lat,
    'lon': lon,
  };

  factory LocationConfig.fromJson(String id, Map<String, dynamic> json) {
    return LocationConfig(
      id: id,
      name: json['name'] as String? ?? (id == 'left' ? '地点1' : '地点2'),
      lat: (json['lat'] as num?)?.toDouble() ?? (id == 'left' ? 35.6895 : 34.6937),
      lon: (json['lon'] as num?)?.toDouble() ?? (id == 'left' ? 139.6917 : 135.5023),
    );
  }
}
