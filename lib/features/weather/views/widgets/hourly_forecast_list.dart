import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme.dart';
import '../../models/weather_code_helper.dart';
import '../../models/weather_data.dart';

class HourlyForecastList extends StatelessWidget {
  final List<HourlyForecast> hourlyForecasts;

  const HourlyForecastList({
    super.key,
    required this.hourlyForecasts,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Filter from current hour until tomorrow 23:59
    final tomorrowEnd = DateTime(now.year, now.month, now.day + 2);

    final filtered = hourlyForecasts.where((h) {
      return h.time.isAfter(now.subtract(const Duration(hours: 1))) &&
          h.time.isBefore(tomorrowEnd);
    }).toList();

    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '1時間ごとの予報（明日24時まで）',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.slate400,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = filtered[index];
              final isRainHigh = item.precipitationProbability >= 50;
              final isNight = item.time.hour < 6 || item.time.hour >= 18;
              final info = WeatherCodeHelper.getInfo(item.weatherCode, isNight: isNight);
              final timeStr = DateFormat('HH:mm').format(item.time);
              final isTomorrowFirst = item.time.hour == 0;

              return Container(
                width: 62,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  color: isRainHigh ? AppColors.rainHighBg : AppColors.slate800,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isRainHigh
                        ? AppColors.rainHighBorder
                        : (isTomorrowFirst ? AppColors.sky400 : AppColors.slate700),
                    width: isTomorrowFirst ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTomorrowFirst ? '明日' : timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isTomorrowFirst ? FontWeight.bold : FontWeight.w500,
                        color: isTomorrowFirst ? AppColors.sky400 : AppColors.slate400,
                      ),
                    ),
                    Icon(info.icon, size: 20, color: info.color),
                    Text(
                      '${item.temperature.toStringAsFixed(0)}°',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate50,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.water_drop,
                          size: 10,
                          color: isRainHigh ? AppColors.sky400 : AppColors.slate500,
                        ),
                        Text(
                          '${item.precipitationProbability}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isRainHigh ? FontWeight.bold : FontWeight.normal,
                            color: isRainHigh ? AppColors.sky400 : AppColors.slate400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
