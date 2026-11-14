import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingResult {
  final String name;
  final double latitude;
  final double longitude;
  final String? country;
  final String? admin1; // Prefecture or state

  const GeocodingResult({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.country,
    this.admin1,
  });

  String get displayName {
    final parts = [
      if (admin1 != null && admin1!.isNotEmpty) admin1!,
      if (country != null && country!.isNotEmpty && country != '日本') country!,
    ];
    if (parts.isEmpty) return name;
    return '$name (${parts.join(', ')})';
  }

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    return GeocodingResult(
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      country: json['country'] as String?,
      admin1: json['admin1'] as String?,
    );
  }
}

class GeocodingService {
  static const Map<String, String> _headers = {
    'User-Agent': 'myinitboard/1.0 (iPadOS; Flutter; Open-Meteo Client)',
    'Accept': 'application/json',
  };

  /// Search locations using Open-Meteo free Geocoding API (no API key required).
  static Future<List<GeocodingResult>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    final uri = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search?'
      'name=${Uri.encodeComponent(trimmed)}&'
      'count=6&'
      'language=ja&'
      'format=json',
    );

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final results = decoded['results'] as List<dynamic>?;
        if (results == null) return [];

        return results
            .map((item) => GeocodingResult.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
