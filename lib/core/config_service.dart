import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/weather/models/location_config.dart';

class ConfigService {
  static const String _keyLocationsListJson = 'custom_locations_list_json';

  // Legacy keys for backward compatibility
  static const String _keyLeftName = 'loc_left_name';
  static const String _keyLeftLat = 'loc_left_lat';
  static const String _keyLeftLon = 'loc_left_lon';
  static const String _keyRightName = 'loc_right_name';
  static const String _keyRightLat = 'loc_right_lat';
  static const String _keyRightLon = 'loc_right_lon';

  // Default fallback locations
  static const List<LocationConfig> defaultLocations = [
    LocationConfig(
      id: 'default_tokyo',
      name: '東京',
      placeName: '東京都',
      lat: 35.6895,
      lon: 139.6917,
    ),
    LocationConfig(
      id: 'default_osaka',
      name: '大阪',
      placeName: '大阪府 大阪市',
      lat: 34.6937,
      lon: 135.5023,
    ),
  ];

  /// Load locations according to priority:
  /// 1. SharedPreferences (JSON list or legacy keys)
  /// 2. assets/local_config.json (if present)
  /// 3. Default fallback list
  static Future<List<LocationConfig>> loadLocations({AssetBundle? bundle}) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. SharedPreferences list
    final jsonListStr = prefs.getString(_keyLocationsListJson);
    if (jsonListStr != null && jsonListStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonListStr) as List<dynamic>;
        final list = decoded
            .map((e) => LocationConfig.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }

    // 1-b. Legacy SharedPreferences
    if (prefs.containsKey(_keyLeftName) && prefs.containsKey(_keyLeftLat)) {
      final list = [
        LocationConfig(
          id: 'legacy_left',
          name: prefs.getString(_keyLeftName) ?? '地点1',
          placeName: prefs.getString(_keyLeftName) ?? '地点1',
          lat: prefs.getDouble(_keyLeftLat) ?? 35.6895,
          lon: prefs.getDouble(_keyLeftLon) ?? 139.6917,
        ),
        if (prefs.containsKey(_keyRightName) && prefs.containsKey(_keyRightLat))
          LocationConfig(
            id: 'legacy_right',
            name: prefs.getString(_keyRightName) ?? '地点2',
            placeName: prefs.getString(_keyRightName) ?? '地点2',
            lat: prefs.getDouble(_keyRightLat) ?? 34.6937,
            lon: prefs.getDouble(_keyRightLon) ?? 135.5023,
          ),
      ];
      return list;
    }

    // 2. assets/local_config.json
    final activeBundle = bundle ?? rootBundle;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(activeBundle);
      final list = manifest.listAssets();
      if (list.contains('assets/local_config.json')) {
        final jsonString = await activeBundle.loadString('assets/local_config.json');
        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

        // Format A: { "locations": [ { "id": "...", "name": "...", "lat": ... } ] }
        if (decoded['locations'] is List) {
          final items = (decoded['locations'] as List)
              .map((e) => LocationConfig.fromJson(e as Map<String, dynamic>))
              .toList();
          if (items.isNotEmpty) return items;
        }

        // Format B (Legacy): { "left": { ... }, "right": { ... } }
        List<LocationConfig> legacyList = [];
        if (decoded['left'] is Map<String, dynamic>) {
          final l = decoded['left'] as Map<String, dynamic>;
          legacyList.add(LocationConfig(
            id: 'local_left',
            name: l['name'] as String? ?? '地点1',
            placeName: l['placeName'] as String? ?? (l['name'] as String? ?? '地点1'),
            lat: (l['lat'] as num?)?.toDouble() ?? 35.6895,
            lon: (l['lon'] as num?)?.toDouble() ?? 139.6917,
          ));
        }
        if (decoded['right'] is Map<String, dynamic>) {
          final r = decoded['right'] as Map<String, dynamic>;
          legacyList.add(LocationConfig(
            id: 'local_right',
            name: r['name'] as String? ?? '地点2',
            placeName: r['placeName'] as String? ?? (r['name'] as String? ?? '地点2'),
            lat: (r['lat'] as num?)?.toDouble() ?? 34.6937,
            lon: (r['lon'] as num?)?.toDouble() ?? 135.5023,
          ));
        }
        if (legacyList.isNotEmpty) return legacyList;
      }
    } catch (_) {}

    // 3. Fallback defaults
    return List.from(defaultLocations);
  }

  /// Save locations list to SharedPreferences
  static Future<void> saveLocations(List<LocationConfig> locations) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonListStr = jsonEncode(locations.map((e) => e.toJson()).toList());
    await prefs.setString(_keyLocationsListJson, jsonListStr);

    // Clean up legacy keys
    await prefs.remove(_keyLeftName);
    await prefs.remove(_keyLeftLat);
    await prefs.remove(_keyLeftLon);
    await prefs.remove(_keyRightName);
    await prefs.remove(_keyRightLat);
    await prefs.remove(_keyRightLon);
  }

  /// Reset to defaults
  static Future<void> resetLocations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLocationsListJson);
    await prefs.remove(_keyLeftName);
    await prefs.remove(_keyLeftLat);
    await prefs.remove(_keyLeftLon);
    await prefs.remove(_keyRightName);
    await prefs.remove(_keyRightLat);
    await prefs.remove(_keyRightLon);
  }
}
