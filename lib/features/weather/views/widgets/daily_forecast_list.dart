import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme.dart';
import '../../models/weather_code_helper.dart';
import '../../models/weather_data.dart';

class DailyForecastList extends StatelessWidget {
  final List<DailyForecast> dailyForecasts;

  const DailyForecastList({
    super.key,
    required this.dailyForecasts,
  });

  static const List<String> _weekdays = ['月', '火', '水', '木', '金', '土', '日'];

  @override
  Widget build(BuildContext context) {
    if (dailyForecasts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '7日間の天気予報',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.slate400,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.slate800,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate700),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dailyForecasts.length,
            separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.slate700),
            itemBuilder: (context, index) {
              final item = dailyForecasts[index];
              final info = WeatherCodeHelper.getInfo(item.weatherCode);
              final weekdayIndex = item.date.weekday - 1; // 1=Mon -> 0
              final weekdayStr = _weekdays[weekdayIndex];
              final isToday = index == 0;
              final isSaturday = item.date.weekday == DateTime.saturday;
              final isSunday = item.date.weekday == DateTime.sunday;

              Color dayColor = AppColors.slate300;
              if (isSunday) {
                dayColor = AppColors.red400;
              } else if (isSaturday) {
                dayColor = AppColors.blue400;
              }

              final isRainHigh = item.precipitationProbabilityMax >= 50;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    // Date & Weekday
                    SizedBox(
                      width: 80,
                      child: Row(
                        children: [
                          Text(
                            isToday ? '今日' : DateFormat('M/d').format(item.date),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                              color: isToday ? AppColors.sky400 : AppColors.slate300,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '($weekdayStr)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: dayColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Icon & Weather description
                    Icon(info.icon, size: 20, color: info.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        info.label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate300,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Precipitation
                    SizedBox(
                      width: 50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.water_drop,
                            size: 11,
                            color: isRainHigh ? AppColors.sky400 : AppColors.slate500,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${item.precipitationProbabilityMax}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isRainHigh ? FontWeight.bold : FontWeight.normal,
                              color: isRainHigh ? AppColors.sky400 : AppColors.slate400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // High / Low Temps
                    SizedBox(
                      width: 72,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${item.tempMax.toStringAsFixed(0)}°',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.red400,
                            ),
                          ),
                          const Text(' / ', style: TextStyle(fontSize: 11, color: AppColors.slate600)),
                          Text(
                            '${item.tempMin.toStringAsFixed(0)}°',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.blue400,
                            ),
                          ),
                        ],
                      ),
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
