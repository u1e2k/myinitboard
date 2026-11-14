import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config_service.dart';
import '../../../../core/theme.dart';
import '../models/location_config.dart';
import '../models/weather_code_helper.dart';
import '../models/weather_data.dart';
import '../services/weather_service.dart';
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
              _buildAppBar(),
              _buildLocationTabBar(),
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

  Widget _buildAppBar() {
    final fetchTime = _latestFetchTime;
    final timeStr = fetchTime != null ? DateFormat('MM/dd HH:mm').format(fetchTime) : '--:--';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.glassBorder, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          // App Logo & Title
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF38BDF8), Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: AppColors.sky400.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 9),
          const Text(
            'myinitboard',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              letterSpacing: -0.2,
              color: AppColors.slate50,
            ),
          ),
          const Spacer(),

          // Status & Last fetch time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: _isAnyFromCache ? AppColors.offlineBg : AppColors.glassSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isAnyFromCache
                    ? AppColors.offlineText.withValues(alpha: 0.4)
                    : AppColors.glassBorderLight,
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6.5,
                  height: 6.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isAnyFromCache ? AppColors.offlineText : const Color(0xFF34D399),
                    boxShadow: [
                      BoxShadow(
                        color: (_isAnyFromCache ? AppColors.offlineText : const Color(0xFF34D399))
                            .withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isAnyFromCache ? 'オフライン ($timeStr)' : '同期: $timeStr',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isAnyFromCache ? AppColors.offlineText : AppColors.slate300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Refresh Button
          IconButton(
            tooltip: '全地点を再取得',
            onPressed: _isLoadingAny ? null : _fetchAllWeather,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.glassSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
                side: const BorderSide(color: AppColors.glassBorder, width: 0.8),
              ),
              padding: const EdgeInsets.all(7),
            ),
            icon: _isLoadingAny
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sky400),
                  )
                : const Icon(Icons.refresh_rounded, color: AppColors.slate200, size: 17),
          ),
          const SizedBox(width: 5),

          // Settings Button
          IconButton(
            tooltip: '登録地点の管理・設定',
            onPressed: _openSettingsDialog,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.glassSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
                side: const BorderSide(color: AppColors.glassBorder, width: 0.8),
              ),
              padding: const EdgeInsets.all(7),
            ),
            icon: const Icon(Icons.settings_outlined, color: AppColors.slate200, size: 17),
          ),
        ],
      ),
    );
  }

  /// Dynamic Location Tab Bar: Supports any number of locations (horizontal scrollable)
  Widget _buildLocationTabBar() {
    if (_locations.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(3.5),
        decoration: BoxDecoration(
          color: AppColors.slate900.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorderLight, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < _locations.length; i++) ...[
                _buildLocationTabItem(
                  index: i,
                  location: _locations[i],
                  weatherData: _weatherDataMap[_locations[i].id],
                ),
                if (i < _locations.length - 1) const SizedBox(width: 4),
              ],
              const SizedBox(width: 4),
              // Quick "Add Location" icon button on tab bar
              InkWell(
                onTap: _openSettingsDialog,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: AppColors.sky400),
                      SizedBox(width: 2),
                      Text(
                        '追加',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sky400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationTabItem({
    required int index,
    required LocationConfig location,
    required LocationWeatherData? weatherData,
  }) {
    final isSelected = _selectedLocationIndex == index;

    IconData? weatherIcon;
    Color? iconColor;
    String? tempText;

    if (weatherData != null) {
      final current = weatherData.current;
      final isNight = current.time.hour < 6 || current.time.hour >= 18;
      final info = WeatherCodeHelper.getInfo(current.weatherCode, isNight: isNight);
      weatherIcon = info.icon;
      iconColor = info.color;
      tempText = '${current.temperature.toStringAsFixed(0)}°';
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedLocationIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sky400 : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.sky400.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Weather Icon (Today's icon)
            if (weatherIcon != null) ...[
              Icon(
                weatherIcon,
                size: 17,
                color: isSelected ? AppColors.slate950 : (iconColor ?? AppColors.sky400),
              ),
              const SizedBox(width: 6),
            ] else ...[
              Icon(
                Icons.place_rounded,
                size: 15,
                color: isSelected ? AppColors.slate950 : AppColors.slate400,
              ),
              const SizedBox(width: 5),
            ],

            // Custom Display Name
            Text(
              location.name,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.slate950 : AppColors.slate200,
              ),
            ),

            // Temperature pill
            if (tempText != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.black.withValues(alpha: 0.15)
                      : AppColors.slate800,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  tempText,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? AppColors.slate950 : AppColors.slate300,
                  ),
                ),
              ),
            ],
          ],
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
