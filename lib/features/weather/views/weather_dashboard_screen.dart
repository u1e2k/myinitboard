import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config_service.dart';
import '../../../../core/theme.dart';
import '../models/location_config.dart';
import '../models/weather_data.dart';
import '../services/weather_service.dart';
import 'widgets/dashboard_app_bar.dart';
import 'widgets/location_tab_bar.dart';
import 'widgets/location_weather_card.dart';
import 'widgets/settings_dialog.dart';

class WeatherDashboardScreen extends StatefulWidget {
  const WeatherDashboardScreen({super.key});

  @override
  State<WeatherDashboardScreen> createState() => _WeatherDashboardScreenState();
}

class _WeatherDashboardScreenState extends State<WeatherDashboardScreen> {
  static const String _keyLastForecastTab = 'last_forecast_tab';

  List<LocationConfig> _locations = [];
  final Map<String, LocationWeatherData> _weatherDataMap = {};
  final Map<String, String> _errorsMap = {};
  final Set<String> _loadingIds = {};

  // Selected location index in _locations
  int _selectedLocationIndex = 0;

  // Forecast display mode: 0: Hourly (1時間毎), 1: Daily (1日毎)
  int _forecastTab = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedForecastTab();
    _loadAndFetchLocations();
  }

  Future<void> _loadSavedForecastTab() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTab = prefs.getInt(_keyLastForecastTab);
    if (savedTab != null && mounted) {
      setState(() => _forecastTab = savedTab);
    }
  }

  Future<void> _setForecastTab(int newTab) async {
    setState(() => _forecastTab = newTab);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastForecastTab, newTab);
  }

  Future<void> _loadAndFetchLocations() async {
    final loaded = await ConfigService.loadLocations();
    setState(() {
      _locations = loaded;
      if (_selectedLocationIndex >= _locations.length) {
        _selectedLocationIndex = 0;
      }
    });

    await _fetchAllWeather();
  }

  Future<void> _fetchAllWeather() async {
    if (_locations.isEmpty) return;

    for (final loc in _locations) {
      _fetchWeatherForLocation(loc);
    }
  }

  Future<void> _fetchWeatherForLocation(LocationConfig loc) async {
    setState(() {
      _loadingIds.add(loc.id);
      _errorsMap.remove(loc.id);
    });

    try {
      final data = await WeatherService.fetchWeather(loc);
      if (mounted) {
        setState(() {
          _weatherDataMap[loc.id] = data;
          _loadingIds.remove(loc.id);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorsMap[loc.id] = e.toString();
          _loadingIds.remove(loc.id);
        });
      }
    }
  }

  Future<void> _handleSaveLocations(List<LocationConfig> newLocations) async {
    await ConfigService.saveLocations(newLocations);
    setState(() {
      _locations = newLocations;
      if (_selectedLocationIndex >= _locations.length) {
        _selectedLocationIndex = 0;
      }
      _weatherDataMap.clear();
      _errorsMap.clear();
    });
    await _fetchAllWeather();
  }

  Future<void> _handleResetLocations() async {
    await ConfigService.resetLocations();
    final defaults = await ConfigService.loadLocations();
    setState(() {
      _locations = defaults;
      _selectedLocationIndex = 0;
      _weatherDataMap.clear();
      _errorsMap.clear();
    });
    await _fetchAllWeather();
  }

  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SettingsDialog(
        locations: _locations,
        onSave: _handleSaveLocations,
        onReset: _handleResetLocations,
      ),
    );
  }

  DateTime? get _latestFetchTime {
    DateTime? latest;
    for (final d in _weatherDataMap.values) {
      if (latest == null || d.fetchedAt.isAfter(latest)) {
        latest = d.fetchedAt;
      }
    }
    return latest;
  }

  bool get _isAnyFromCache {
    return _weatherDataMap.values.any((d) => d.isFromCache);
  }

  bool get _isLoadingAny {
    return _loadingIds.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF070B14),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              DashboardAppBar(
                latestFetchTime: _latestFetchTime,
                isAnyFromCache: _isAnyFromCache,
                isLoading: _isLoadingAny,
                onRefresh: _fetchAllWeather,
                onOpenSettings: _openSettingsDialog,
              ),
              LocationTabBar(
                locations: _locations,
                selectedIndex: _selectedLocationIndex,
                weatherDataMap: _weatherDataMap,
                onSelectIndex: (idx) => setState(() => _selectedLocationIndex = idx),
                onAddLocation: _openSettingsDialog,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isLandscape = constraints.maxWidth >= 850;
                    return _buildMainContent(isLandscape);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Main content view: Displays the single selected location comfortably
  Widget _buildMainContent(bool isLandscape) {
    if (_locations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_rounded, size: 48, color: AppColors.slate500),
            const SizedBox(height: 12),
            const Text(
              '地点が登録されていません',
              style: TextStyle(color: AppColors.slate300, fontSize: 14),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _openSettingsDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('地点を登録する'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.sky400,
                foregroundColor: AppColors.slate950,
              ),
            ),
          ],
        ),
      );
    }

    final activeLocation = _locations[_selectedLocationIndex];
    final activeData = _weatherDataMap[activeLocation.id];
    final activeLoading = _loadingIds.contains(activeLocation.id);
    final activeError = _errorsMap[activeLocation.id];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: LocationWeatherCard(
            key: ValueKey(activeLocation.id),
            data: activeData,
            isLoading: activeLoading,
            errorMessage: activeError,
            onRetry: () => _fetchWeatherForLocation(activeLocation),
            isLandscape: isLandscape,
            forecastTab: _forecastTab,
            onForecastTabChanged: _setForecastTab,
          ),
        ),
      ),
    );
  }
}
