import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/weather/models/location_config.dart';

class ConfigService {
  static const String _keyLeftName = 'loc_left_name';
  static const String _keyLeftLat = 'loc_left_lat';
  static const String _keyLeftLon = 'loc_left_lon';

  static const String _keyRightName = 'loc_right_name';
  static const String _keyRightLat = 'loc_right_lat';
  static const String _keyRightLon = 'loc_right_lon';

  // Fallback default coordinates (Tokyo & Osaka)
  static const LocationConfig defaultLeft = LocationConfig(
    id: 'left',
    name: '東京',
    lat: 35.6895,
    lon: 139.6917,
  );

  static const LocationConfig defaultRight = LocationConfig(
    id: 'right',
    name: '大阪',
    lat: 34.6937,
    lon: 135.5023,
  );

  /// Load locations according to priority:
  /// 1. SharedPreferences (User saved)
  /// 2. assets/local_config.json (if present in asset manifest)
  /// 3. Fallback defaults (Tokyo & Osaka)
  static Future<({LocationConfig left, LocationConfig right})> loadLocations({
    AssetBundle? bundle,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final hasLeftPrefs = prefs.containsKey(_keyLeftName) &&
        prefs.containsKey(_keyLeftLat) &&
        prefs.containsKey(_keyLeftLon);

    final hasRightPrefs = prefs.containsKey(_keyRightName) &&
        prefs.containsKey(_keyRightLat) &&
        prefs.containsKey(_keyRightLon);

    // 1. If both are saved in SharedPreferences, use them directly
    if (hasLeftPrefs && hasRightPrefs) {
      final left = LocationConfig(
        id: 'left',
        name: prefs.getString(_keyLeftName) ?? defaultLeft.name,
        lat: prefs.getDouble(_keyLeftLat) ?? defaultLeft.lat,
        lon: prefs.getDouble(_keyLeftLon) ?? defaultLeft.lon,
      );
      final right = LocationConfig(
        id: 'right',
        name: prefs.getString(_keyRightName) ?? defaultRight.name,
        lat: prefs.getDouble(_keyRightLat) ?? defaultRight.lat,
        lon: prefs.getDouble(_keyRightLon) ?? defaultRight.lon,
      );
      return (left: left, right: right);
    }

    // 2. Check assets/local_config.json safely via AssetManifest
    Map<String, dynamic>? localJson;
    final activeBundle = bundle ?? rootBundle;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(activeBundle);
      final list = manifest.listAssets();
      if (list.contains('assets/local_config.json')) {
        final jsonString = await activeBundle.loadString('assets/local_config.json');
        localJson = jsonDecode(jsonString) as Map<String, dynamic>?;
      }
    } catch (_) {
      localJson = null;
    }

    // 3. Resolve left location
    LocationConfig left;
    if (hasLeftPrefs) {
      left = LocationConfig(
        id: 'left',
        name: prefs.getString(_keyLeftName)!,
        lat: prefs.getDouble(_keyLeftLat)!,
        lon: prefs.getDouble(_keyLeftLon)!,
      );
    } else if (localJson != null && localJson['left'] is Map<String, dynamic>) {
      left = LocationConfig.fromJson('left', localJson['left'] as Map<String, dynamic>);
    } else {
      left = defaultLeft;
    }

    // 3. Resolve right location
    LocationConfig right;
    if (hasRightPrefs) {
      right = LocationConfig(
        id: 'right',
        name: prefs.getString(_keyRightName)!,
        lat: prefs.getDouble(_keyRightLat)!,
        lon: prefs.getDouble(_keyRightLon)!,
      );
    } else if (localJson != null && localJson['right'] is Map<String, dynamic>) {
      right = LocationConfig.fromJson('right', localJson['right'] as Map<String, dynamic>);
    } else {
      right = defaultRight;
    }

    return (left: left, right: right);
  }

  /// Save user custom locations to SharedPreferences
  static Future<void> saveLocations({
    required LocationConfig left,
    required LocationConfig right,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLeftName, left.name);
    await prefs.setDouble(_keyLeftLat, left.lat);
    await prefs.setDouble(_keyLeftLon, left.lon);

    await prefs.setString(_keyRightName, right.name);
    await prefs.setDouble(_keyRightLat, right.lat);
    await prefs.setDouble(_keyRightLon, right.lon);
  }

  /// Reset to defaults (removes SharedPreferences keys so it falls back to local_config.json or hardcoded default)
  static Future<void> resetLocations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLeftName);
    await prefs.remove(_keyLeftLat);
    await prefs.remove(_keyLeftLon);
    await prefs.remove(_keyRightName);
    await prefs.remove(_keyRightLat);
    await prefs.remove(_keyRightLon);
  }
}
