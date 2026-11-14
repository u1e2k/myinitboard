import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_config.dart';
import '../models/weather_data.dart';

class WeatherService {
  static const String _cacheKeyPrefixJson = 'cached_weather_json_';
  static const String _cacheKeyPrefixTime = 'cached_weather_time_';

  /// Fetch weather for a given location.
  /// If online and successful: parses JSON, saves to cache, returns data.
  /// If offline or request fails: tries to load from cache.
  /// If no cache exists: rethrows error.
  static Future<LocationWeatherData> fetchWeather(LocationConfig location) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?'
      'latitude=${location.lat}&longitude=${location.lon}&'
      'current=temperature_2m,relative_humidity_2m,weather_code,apparent_temperature&'
      'hourly=temperature_2m,precipitation_probability,weather_code&'
      'daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max&'
      'timezone=Asia%2FTokyo&'
      'forecast_days=7',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final now = DateTime.now();

        // Save to cache
        await _saveToCache(location.id, response.body, now);

        return LocationWeatherData.fromOpenMeteoJson(
          location: location,
          json: decoded,
          fetchedAt: now,
          isFromCache: false,
        );
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // Failed to fetch from network. Try cache fallback.
      final cached = await _loadFromCache(location);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  static Future<void> _saveToCache(String locationId, String jsonString, DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_cacheKeyPrefixJson$locationId', jsonString);
    await prefs.setString('$_cacheKeyPrefixTime$locationId', time.toIso8601String());
  }

  static Future<LocationWeatherData?> _loadFromCache(LocationConfig location) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('$_cacheKeyPrefixJson${location.id}');
    final timeString = prefs.getString('$_cacheKeyPrefixTime${location.id}');

    if (jsonString != null && timeString != null) {
      try {
        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
        final cachedTime = DateTime.parse(timeString);
        return LocationWeatherData.fromOpenMeteoJson(
          location: location,
          json: decoded,
          fetchedAt: cachedTime,
          isFromCache: true,
        );
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
