import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../models/weather_data.dart';
import 'current_weather_banner.dart';
import 'daily_forecast_list.dart';
import 'hourly_forecast_list.dart';
import 'time_period_summary_grid.dart';

class LocationWeatherCard extends StatelessWidget {
  final LocationWeatherData? data;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool isLandscape;
  final int forecastTab; // 0: 1時間毎, 1: 1日毎, 2: すべて表示
  final ValueChanged<int>? onForecastTabChanged;

  const LocationWeatherCard({
    super.key,
    required this.data,
    required this.isLoading,
    this.errorMessage,
    this.onRetry,
    required this.isLandscape,
    this.forecastTab = 2,
    this.onForecastTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && data == null) {
      return Container(
        height: 380,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.slate900.withValues(alpha: 0.7),
          border: Border.all(color: AppColors.glassBorderLight, width: 0.8),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.sky400, strokeWidth: 2.5),
              SizedBox(height: 14),
              Text(
                '気象データを同期中...',
                style: TextStyle(color: AppColors.slate400, fontSize: 13, letterSpacing: 0.3),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null && data == null) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.slate900.withValues(alpha: 0.8),
          border: Border.all(color: AppColors.tempHot.withValues(alpha: 0.4), width: 0.8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.tempHot.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.tempHot),
              ),
              const SizedBox(height: 14),
              Text(
                'データ取得に失敗しました\n$errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.slate300, fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (onRetry != null)
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 17),
                  label: const Text('再試行'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.sky400,
                    foregroundColor: AppColors.slate950,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (data == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF161F33),
            Color(0xFF0F1626),
          ],
        ),
        border: Border.all(color: AppColors.glassBorderLight, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout(),
    );
  }

  /// iPad 横画面向けレイアウト（幅1133ptを2カラムで有効活用し横の余白を解消）
  Widget _buildLandscapeLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左カラム: 現在の天気バナー ＆ 時間帯サマリー
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CurrentWeatherBanner(weatherData: data!),
              const SizedBox(height: 12),
              TimePeriodSummaryGrid(
                summaries: data!.periodSummaries,
                isLandscape: true,
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        // 右カラム: 予報切り替えヘッダー ＆ 予報リスト
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildForecastHeader(),
              const SizedBox(height: 8),
              _buildForecastContent(),
            ],
          ),
        ),
      ],
    );
  }

  /// iPad 縦画面向けレイアウト（高さ1133ptをフル活用し縦の余白を解消）
  Widget _buildPortraitLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CurrentWeatherBanner(weatherData: data!),
        const SizedBox(height: 12),
        TimePeriodSummaryGrid(
          summaries: data!.periodSummaries,
          isLandscape: false,
        ),
        const SizedBox(height: 14),
        _buildForecastHeader(),
        const SizedBox(height: 8),
        _buildForecastContent(),
      ],
    );
  }

  Widget _buildForecastHeader() {
    String headerTitle;
    IconData headerIcon;

    if (forecastTab == 2) {
      headerTitle = '詳細天気予報（時間別 ＆ 週間）';
      headerIcon = Icons.dashboard_customize_rounded;
    } else if (forecastTab == 0) {
      headerTitle = '1時間ごとの予報（明日24時まで）';
      headerIcon = Icons.schedule_rounded;
    } else {
      headerTitle = '7日間の日別予報';
      headerIcon = Icons.calendar_month_rounded;
    }

    return Row(
      children: [
        Icon(headerIcon, size: 15, color: AppColors.sky400),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            headerTitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.slate300,
              letterSpacing: 0.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.glassBorder, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabButton('すべて', 2, Icons.view_quilt_rounded),
              _buildTabButton('1時間毎', 0, Icons.access_time_rounded),
              _buildTabButton('1日毎', 1, Icons.calendar_view_week_rounded),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForecastContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: forecastTab == 2
          ? Column(
              key: const ValueKey('all_forecasts'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HourlyForecastList(
                  hourlyForecasts: data!.hourly,
                  showHeader: true,
                ),
                const SizedBox(height: 12),
                DailyForecastList(
                  dailyForecasts: data!.daily,
                  showHeader: true,
                ),
              ],
            )
          : forecastTab == 0
              ? HourlyForecastList(
                  key: const ValueKey('hourly_only'),
                  hourlyForecasts: data!.hourly,
                  showHeader: false,
                )
              : DailyForecastList(
                  key: const ValueKey('daily_only'),
                  dailyForecasts: data!.daily,
                  showHeader: false,
                ),
    );
  }

  Widget _buildTabButton(String label, int index, IconData icon) {
    final isSelected = forecastTab == index;

    return GestureDetector(
      onTap: () {
        if (forecastTab != index && onForecastTabChanged != null) {
          onForecastTabChanged!(index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sky400 : Colors.transparent,
          borderRadius: BorderRadius.circular(6.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.sky400.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 11.5,
              color: isSelected ? AppColors.slate950 : AppColors.slate400,
            ),
            const SizedBox(width: 3.5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? AppColors.slate950 : AppColors.slate400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
