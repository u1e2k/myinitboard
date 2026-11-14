import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/config_service.dart';
import '../../../../core/theme.dart';
import '../models/location_config.dart';
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
  LocationConfig? _leftLocation;
  LocationConfig? _rightLocation;

  LocationWeatherData? _leftWeatherData;
  LocationWeatherData? _rightWeatherData;

  bool _isLoading = false;
  String? _leftError;
  String? _rightError;

  // Selected view mode for portrait screen: 0: Both (vertical), 1: Left only, 2: Right only
  int _portraitViewMode = 0;

  @override
  void initState() {
    super.initState();
    _loadAndFetch();
  }

  Future<void> _loadAndFetch() async {
    setState(() {
      _isLoading = true;
      _leftError = null;
      _rightError = null;
    });

    final locations = await ConfigService.loadLocations();
    _leftLocation = locations.left;
    _rightLocation = locations.right;

    await _fetchBoth();
  }

  Future<void> _fetchBoth() async {
    if (_leftLocation == null || _rightLocation == null) return;

    setState(() => _isLoading = true);

    final leftFuture = WeatherService.fetchWeather(_leftLocation!).then((data) {
      if (mounted) setState(() => _leftWeatherData = data);
    }).catchError((e) {
      if (mounted) setState(() => _leftError = e.toString());
    });

    final rightFuture = WeatherService.fetchWeather(_rightLocation!).then((data) {
      if (mounted) setState(() => _rightWeatherData = data);
    }).catchError((e) {
      if (mounted) setState(() => _rightError = e.toString());
    });

    await Future.wait([leftFuture, rightFuture]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSaveLocations(LocationConfig newLeft, LocationConfig newRight) async {
    await ConfigService.saveLocations(left: newLeft, right: newRight);
    setState(() {
      _leftLocation = newLeft;
      _rightLocation = newRight;
      _leftWeatherData = null;
      _rightWeatherData = null;
    });
    await _fetchBoth();
  }

  Future<void> _handleResetLocations() async {
    await ConfigService.resetLocations();
    final defaults = await ConfigService.loadLocations();
    setState(() {
      _leftLocation = defaults.left;
      _rightLocation = defaults.right;
      _leftWeatherData = null;
      _rightWeatherData = null;
    });
    await _fetchBoth();
  }

  void _openSettingsDialog() {
    if (_leftLocation == null || _rightLocation == null) return;
    showDialog(
      context: context,
      builder: (ctx) => SettingsDialog(
        leftLocation: _leftLocation!,
        rightLocation: _rightLocation!,
        onSave: _handleSaveLocations,
        onReset: _handleResetLocations,
      ),
    );
  }

  DateTime? get _latestFetchTime {
    if (_leftWeatherData != null && _rightWeatherData != null) {
      return _leftWeatherData!.fetchedAt.isAfter(_rightWeatherData!.fetchedAt)
          ? _leftWeatherData!.fetchedAt
          : _rightWeatherData!.fetchedAt;
    }
    return _leftWeatherData?.fetchedAt ?? _rightWeatherData?.fetchedAt;
  }

  bool get _isAnyFromCache {
    return (_leftWeatherData?.isFromCache ?? false) || (_rightWeatherData?.isFromCache ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth >= 850;

          if (isLandscape) {
            return _buildLandscapeLayout();
          } else {
            return _buildPortraitLayout();
          }
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final fetchTime = _latestFetchTime;
    final timeStr = fetchTime != null ? DateFormat('MM/dd HH:mm').format(fetchTime) : '--:--';

    return AppBar(
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.sky400.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.dashboard_customize_rounded, color: AppColors.sky400, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'myinitboard',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: 0.5,
              color: AppColors.slate50,
            ),
          ),
        ],
      ),
      actions: [
        // Status & Last fetch time badge
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _isAnyFromCache ? AppColors.offlineBg : AppColors.slate800,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isAnyFromCache ? AppColors.offlineText.withValues(alpha: 0.4) : AppColors.slate700,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isAnyFromCache ? Icons.cloud_off_outlined : Icons.check_circle_outline,
                size: 14,
                color: _isAnyFromCache ? AppColors.offlineText : AppColors.sky400,
              ),
              const SizedBox(width: 6),
              Text(
                _isAnyFromCache ? 'オフライン表示 ($timeStr)' : '取得: $timeStr',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _isAnyFromCache ? AppColors.offlineText : AppColors.slate300,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Refresh Button
        IconButton(
          tooltip: '手動更新',
          onPressed: _isLoading ? null : _fetchBoth,
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sky400),
                )
              : const Icon(Icons.refresh_rounded, color: AppColors.slate300),
        ),

        // Settings Button
        IconButton(
          tooltip: '地点設定',
          onPressed: _openSettingsDialog,
          icon: const Icon(Icons.settings_outlined, color: AppColors.slate300),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Horizontal 2-column layout (Width >= 850pt)
  Widget _buildLandscapeLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left location column
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 20),
            child: LocationWeatherCard(
              data: _leftWeatherData,
              isLoading: _isLoading,
              errorMessage: _leftError,
              onRetry: _fetchBoth,
              isLandscape: true,
            ),
          ),
        ),
        // Right location column
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
            child: LocationWeatherCard(
              data: _rightWeatherData,
              isLoading: _isLoading,
              errorMessage: _rightError,
              onRetry: _fetchBoth,
              isLandscape: true,
            ),
          ),
        ),
      ],
    );
  }

  /// Vertical layout (Width < 850pt)
  Widget _buildPortraitLayout() {
    final leftName = _leftLocation?.name ?? '地点1';
    final rightName = _rightLocation?.name ?? '地点2';

    return Column(
      children: [
        // Segment control for viewing mode
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.slate900,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.slate800,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.slate700),
            ),
            child: Row(
              children: [
                _buildSegmentItem('2地点並び', 0),
                _buildSegmentItem(leftName, 1),
                _buildSegmentItem(rightName, 2),
              ],
            ),
          ),
        ),
        // Content Area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              children: [
                if (_portraitViewMode == 0 || _portraitViewMode == 1) ...[
                  LocationWeatherCard(
                    data: _leftWeatherData,
                    isLoading: _isLoading,
                    errorMessage: _leftError,
                    onRetry: _fetchBoth,
                    isLandscape: false,
                  ),
                ],
                if (_portraitViewMode == 0) const SizedBox(height: 16),
                if (_portraitViewMode == 0 || _portraitViewMode == 2) ...[
                  LocationWeatherCard(
                    data: _rightWeatherData,
                    isLoading: _isLoading,
                    errorMessage: _rightError,
                    onRetry: _fetchBoth,
                    isLandscape: false,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentItem(String title, int index) {
    final isSelected = _portraitViewMode == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _portraitViewMode = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.sky400 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.slate950 : AppColors.slate400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
