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

  const LocationWeatherCard({
    super.key,
    required this.data,
    required this.isLoading,
    this.errorMessage,
    this.onRetry,
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && data == null) {
      return Container(
        height: 380,
        decoration: BoxDecoration(
          color: AppColors.slate800.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate700),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.sky400),
              SizedBox(height: 12),
              Text(
                '天気データを取得中...',
                style: TextStyle(color: AppColors.slate400, fontSize: 13),
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
          color: AppColors.slate800,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate700),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.red400),
              const SizedBox(height: 12),
              Text(
                'データ取得に失敗しました\n$errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.slate300, fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (onRetry != null)
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('再試行'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.sky400,
                    foregroundColor: AppColors.slate950,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.slate800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Current Weather Banner
          CurrentWeatherBanner(weatherData: data!),
          const SizedBox(height: 14),

          // 2. Time Period Summary (Today/Tomorrow morning/afternoon/night)
          TimePeriodSummaryGrid(
            summaries: data!.periodSummaries,
            isLandscape: isLandscape,
          ),
          const SizedBox(height: 14),

          // 3. Hourly Forecast (until tomorrow 24:00)
          HourlyForecastList(hourlyForecasts: data!.hourly),
          const SizedBox(height: 14),

          // 4. Daily Forecast (7 days)
          DailyForecastList(dailyForecasts: data!.daily),
        ],
      ),
    );
  }
}
