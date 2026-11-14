import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme.dart';
import '../../models/weather_code_helper.dart';
import '../../models/weather_data.dart';
import 'temp_range_bar.dart';

class DailyForecastList extends StatelessWidget {
  final List<DailyForecast> dailyForecasts;
  final bool showHeader;

  const DailyForecastList({
    super.key,
    required this.dailyForecasts,
    this.showHeader = true,
  });

  static const List<String> _weekdays = ['月', '火', '水', '木', '金', '土', '日'];

  @override
  Widget build(BuildContext context) {
    if (dailyForecasts.isEmpty) return const SizedBox.shrink();

    // Find the week's overall min and max temperatures to normalize range bars
    double overallMin = dailyForecasts.map((d) => d.tempMin).reduce(math.min);
    double overallMax = dailyForecasts.map((d) => d.tempMax).reduce(math.max);
    if ((overallMax - overallMin).abs() < 1.0) {
      overallMax += 1.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHeader) ...[
          const Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.sky400),
              SizedBox(width: 6),
              Text(
                '7日間の天気予報',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate300,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.slate900.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.glassBorderLight, width: 0.8),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dailyForecasts.length,
            separatorBuilder: (_, _) => const Divider(
              height: 1,
              color: AppColors.glassBorder,
              indent: 12,
              endIndent: 12,
            ),
            itemBuilder: (context, index) {
              final item = dailyForecasts[index];
              final info = WeatherCodeHelper.getInfo(item.weatherCode);
              final weekdayIndex = item.date.weekday - 1;
              final weekdayStr = _weekdays[weekdayIndex];
              final isToday = index == 0;
              final isSaturday = item.date.weekday == DateTime.saturday;
              final isSunday = item.date.weekday == DateTime.sunday;

              Color dayColor = AppColors.slate300;
              if (isSunday) {
                dayColor = AppColors.tempHot;
              } else if (isSaturday) {
                dayColor = AppColors.sky400;
              }

              final isRainHigh = item.precipitationProbabilityMax >= 50;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                child: Row(
                  children: [
                    // Date & Weekday badge
                    SizedBox(
                      width: 72,
                      child: Row(
                        children: [
                          Text(
                            isToday ? '今日' : DateFormat('M/d').format(item.date),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                              color: isToday ? AppColors.sky400 : AppColors.slate200,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '($weekdayStr)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: dayColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Weather Icon & Label
                    Icon(info.icon, size: 18, color: info.color),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Text(
                        info.label,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate300,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Precipitation Probability Pill
                    SizedBox(
                      width: 46,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (item.precipitationProbabilityMax > 0) ...[
                            Icon(
                              Icons.water_drop,
                              size: 10,
                              color: isRainHigh ? AppColors.sky400 : AppColors.slate500,
                            ),
                            const SizedBox(width: 1),
                            Text(
                              '${item.precipitationProbabilityMax}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isRainHigh ? FontWeight.w800 : FontWeight.w500,
                                color: isRainHigh ? AppColors.sky300 : AppColors.slate400,
                              ),
                            ),
                          ] else ...[
                            const Text(
                              '-',
                              style: TextStyle(fontSize: 11, color: AppColors.slate600),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Low Temperature
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${item.tempMin.toStringAsFixed(0)}°',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tempCold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Visual Temperature Range Bar (iOS style)
                    Expanded(
                      flex: 3,
                      child: TempRangeBar(
                        min: item.tempMin,
                        max: item.tempMax,
                        overallMin: overallMin,
                        overallMax: overallMax,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // High Temperature
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${item.tempMax.toStringAsFixed(0)}°',
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tempHot,
                        ),
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
