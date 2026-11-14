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
    final isNight = current.time.hour < 6 || current.time.hour >= 18;
    final info = WeatherCodeHelper.getInfo(current.weatherCode, isNight: isNight);
    final todayDaily = weatherData.daily.isNotEmpty ? weatherData.daily.first : null;

    // Ambient gradient tint based on weather condition
    final (tintStart, tintEnd) = _getWeatherGradients(current.weatherCode, isNight);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tintStart, tintEnd],
        ),
        border: Border.all(color: AppColors.glassBorderLight, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Weather condition icon in a glowing circle
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      info.color.withValues(alpha: 0.25),
                      info.color.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: info.color.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Icon(info.icon, color: info.color, size: 32),
              ),
              const SizedBox(width: 14),

              // Location Name, Label, and Condition
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: AppColors.sky400,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            weatherData.location.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate50,
                              letterSpacing: 0.2,
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
                              border: Border.all(color: AppColors.offlineText.withValues(alpha: 0.3), width: 0.5),
                            ),
                            child: const Text(
                              'キャッシュ',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.offlineText,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          info.label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.slate300,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '体感 ${current.apparentTemperature.toStringAsFixed(1)}°',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.slate400,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '湿度 ${current.humidity}%',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.slate400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Temperature and High / Low
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${current.temperature.toStringAsFixed(1)}°',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate50,
                      height: 1.0,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (todayDaily != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_upward_rounded, size: 10, color: AppColors.tempHot),
                          Text(
                            '${todayDaily.tempMax.toStringAsFixed(0)}°',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tempHot,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_downward_rounded, size: 10, color: AppColors.tempCold),
                          Text(
                            '${todayDaily.tempMin.toStringAsFixed(0)}°',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tempCold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, Color) _getWeatherGradients(int code, bool isNight) {
    if (isNight) {
      return (const Color(0xFF161E36), const Color(0xFF0F1424));
    }
    if (code == 0 || code == 1) {
      // Sunny warm tint
      return (const Color(0xFF26232E), const Color(0xFF141926));
    }
    if (code >= 61 && code <= 82) {
      // Rainy deep cool tint
      return (const Color(0xFF10283E), const Color(0xFF0E1A2E));
    }
    if (code >= 71) {
      // Snow frosty tint
      return (const Color(0xFF1B2433), const Color(0xFF141926));
    }
    return (const Color(0xFF1B2436), const Color(0xFF121824));
  }
}
