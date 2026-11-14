import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme.dart';
import '../../models/weather_code_helper.dart';
import '../../models/weather_data.dart';

class HourlyForecastList extends StatelessWidget {
  final List<HourlyForecast> hourlyForecasts;
  final bool showHeader;

  const HourlyForecastList({
    super.key,
    required this.hourlyForecasts,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
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
        if (showHeader) ...[
          const Row(
            children: [
              Icon(Icons.schedule_rounded, size: 14, color: AppColors.sky400),
              SizedBox(width: 6),
              Text(
                '1時間ごとの予報（明日24時まで）',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate300,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final item = filtered[index];
              final isRainHigh = item.precipitationProbability >= 50;
              final isNight = item.time.hour < 6 || item.time.hour >= 18;
              final info = WeatherCodeHelper.getInfo(item.weatherCode, isNight: isNight);
              final timeStr = DateFormat('HH:mm').format(item.time);
              final isTomorrowBoundary = item.time.hour == 0;
              final isCurrentHour = index == 0 &&
                  (item.time.hour == now.hour && item.time.day == now.day);

              return Container(
                width: 64,
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isRainHigh
                        ? [
                            const Color(0xFF0C2B47),
                            const Color(0xFF081C30),
                          ]
                        : isTomorrowBoundary
                            ? [
                                const Color(0xFF1E2845),
                                const Color(0xFF131A30),
                              ]
                            : [
                                const Color(0xFF1A2336),
                                const Color(0xFF111724),
                              ],
                  ),
                  border: Border.all(
                    color: isRainHigh
                        ? AppColors.sky400
                        : isTomorrowBoundary
                            ? AppColors.indigo500.withValues(alpha: 0.6)
                            : isCurrentHour
                                ? AppColors.sky400.withValues(alpha: 0.5)
                                : AppColors.glassBorderLight,
                    width: (isRainHigh || isTomorrowBoundary || isCurrentHour) ? 1.2 : 0.8,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Time Label (今 / 明日 / HH:mm)
                    Text(
                      isCurrentHour
                          ? '今'
                          : isTomorrowBoundary
                              ? '明日'
                              : timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: (isTomorrowBoundary || isCurrentHour)
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isCurrentHour
                            ? AppColors.sky300
                            : isTomorrowBoundary
                                ? const Color(0xFFA5B4FC)
                                : AppColors.slate300,
                      ),
                    ),

                    // Weather Icon
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: info.color.withValues(alpha: 0.1),
                      ),
                      child: Icon(info.icon, size: 21, color: info.color),
                    ),

                    // Temperature
                    Text(
                      '${item.temperature.toStringAsFixed(0)}°',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate50,
                      ),
                    ),

                    // Rain probability
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.water_drop,
                          size: 9.5,
                          color: isRainHigh ? AppColors.sky400 : AppColors.slate500,
                        ),
                        const SizedBox(width: 1),
                        Text(
                          '${item.precipitationProbability}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isRainHigh ? FontWeight.w800 : FontWeight.w500,
                            color: isRainHigh ? AppColors.sky300 : AppColors.slate400,
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
