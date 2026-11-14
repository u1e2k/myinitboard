import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../models/weather_code_helper.dart';
import '../../models/weather_data.dart';

class CurrentWeatherBanner extends StatelessWidget {
  final LocationWeatherData weatherData;

  const CurrentWeatherBanner({
    super.key,
    required this.weatherData,
  });

  @override
  Widget build(BuildContext context) {
    final current = weatherData.current;
    final info = WeatherCodeHelper.getInfo(
      current.weatherCode,
      isNight: current.time.hour < 6 || current.time.hour >= 18,
    );

    // Today's daily forecast for high/low
    final todayDaily = weatherData.daily.isNotEmpty ? weatherData.daily.first : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.slate850,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate700),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Weather Icon with glow effect
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(info.icon, color: info.color, size: 32),
          ),
          const SizedBox(width: 14),
          // Location Name & Weather Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        weatherData.location.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate50,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (weatherData.isFromCache) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.offlineBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'キャッシュ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.offlineText,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  info.label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.slate400,
                  ),
                ),
              ],
            ),
          ),
          // Temperature & High/Low
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${current.temperature.toStringAsFixed(1)}°',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate50,
                  height: 1.1,
                ),
              ),
              if (todayDaily != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${todayDaily.tempMax.toStringAsFixed(0)}°',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.red400,
                      ),
                    ),
                    const Text(' / ', style: TextStyle(fontSize: 11, color: AppColors.slate600)),
                    Text(
                      '${todayDaily.tempMin.toStringAsFixed(0)}°',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue400,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
