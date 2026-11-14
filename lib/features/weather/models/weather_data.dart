import 'location_config.dart';

class CurrentWeather {
  final double temperature;
  final double apparentTemperature;
  final int humidity;
  final int weatherCode;
  final DateTime time;

  const CurrentWeather({
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.weatherCode,
    required this.time,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature: (json['temperature_2m'] as num).toDouble(),
      apparentTemperature: (json['apparent_temperature'] as num?)?.toDouble() ??
          (json['temperature_2m'] as num).toDouble(),
      humidity: (json['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      weatherCode: (json['weather_code'] as num).toInt(),
      time: DateTime.parse(json['time'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'temperature_2m': temperature,
    'apparent_temperature': apparentTemperature,
    'relative_humidity_2m': humidity,
    'weather_code': weatherCode,
    'time': time.toIso8601String(),
  };
}

class HourlyForecast {
  final DateTime time;
  final double temperature;
  final int precipitationProbability;
  final int weatherCode;

  const HourlyForecast({
    required this.time,
    required this.temperature,
    required this.precipitationProbability,
    required this.weatherCode,
  });

  Map<String, dynamic> toJson() => {
    'time': time.toIso8601String(),
    'temperature_2m': temperature,
    'precipitation_probability': precipitationProbability,
    'weather_code': weatherCode,
  };
}

class DailyForecast {
  final DateTime date;
  final int weatherCode;
  final double tempMax;
  final double tempMin;
  final int precipitationProbabilityMax;

  const DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.tempMax,
    required this.tempMin,
    required this.precipitationProbabilityMax,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'weather_code': weatherCode,
    'temperature_2m_max': tempMax,
    'temperature_2m_min': tempMin,
    'precipitation_probability_max': precipitationProbabilityMax,
  };
}

class TimePeriodSummary {
  final String dayLabel;    // "今日" or "明日"
  final String periodLabel; // "午前 (6-12時)", "午後 (12-18時)", "夜 (18-24時)"
  final String periodShort; // "午前", "午後", "夜"
  final DateTime targetDate;
  final int weatherCode;
  final int maxPrecipitationProbability;
  final double maxTemp;
  final double minTemp;

  bool get isRainHigh => maxPrecipitationProbability >= 50;

  const TimePeriodSummary({
    required this.dayLabel,
    required this.periodLabel,
    required this.periodShort,
    required this.targetDate,
    required this.weatherCode,
    required this.maxPrecipitationProbability,
    required this.maxTemp,
    required this.minTemp,
  });
}

class LocationWeatherData {
  final LocationConfig location;
  final CurrentWeather current;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;
  final List<TimePeriodSummary> periodSummaries;
  final DateTime fetchedAt;
  final bool isFromCache;

  const LocationWeatherData({
    required this.location,
    required this.current,
    required this.hourly,
    required this.daily,
    required this.periodSummaries,
    required this.fetchedAt,
    this.isFromCache = false,
  });

  factory LocationWeatherData.fromOpenMeteoJson({
    required LocationConfig location,
    required Map<String, dynamic> json,
    required DateTime fetchedAt,
    bool isFromCache = false,
  }) {
    final current = CurrentWeather.fromJson(json['current'] as Map<String, dynamic>);

    // Hourly
    final hourlyMap = json['hourly'] as Map<String, dynamic>;
    final List<dynamic> times = hourlyMap['time'] as List<dynamic>;
    final List<dynamic> temps = hourlyMap['temperature_2m'] as List<dynamic>;
    final List<dynamic> precips = (hourlyMap['precipitation_probability'] as List<dynamic>?) ?? [];
    final List<dynamic> codes = hourlyMap['weather_code'] as List<dynamic>;

    final List<HourlyForecast> allHourly = [];
    for (int i = 0; i < times.length; i++) {
      allHourly.add(HourlyForecast(
        time: DateTime.parse(times[i] as String),
        temperature: (temps[i] as num).toDouble(),
        precipitationProbability: precips.isNotEmpty ? (precips[i] as num?)?.toInt() ?? 0 : 0,
        weatherCode: (codes[i] as num).toInt(),
      ));
    }

    // Daily
    final dailyMap = json['daily'] as Map<String, dynamic>;
    final List<dynamic> dTimes = dailyMap['time'] as List<dynamic>;
    final List<dynamic> dCodes = dailyMap['weather_code'] as List<dynamic>;
    final List<dynamic> dMaxs = dailyMap['temperature_2m_max'] as List<dynamic>;
    final List<dynamic> dMins = dailyMap['temperature_2m_min'] as List<dynamic>;
    final List<dynamic> dPrecips = (dailyMap['precipitation_probability_max'] as List<dynamic>?) ?? [];

    final List<DailyForecast> allDaily = [];
    for (int i = 0; i < dTimes.length; i++) {
      allDaily.add(DailyForecast(
        date: DateTime.parse(dTimes[i] as String),
        weatherCode: (dCodes[i] as num).toInt(),
        tempMax: (dMaxs[i] as num).toDouble(),
        tempMin: (dMins[i] as num).toDouble(),
        precipitationProbabilityMax: dPrecips.isNotEmpty ? (dPrecips[i] as num?)?.toInt() ?? 0 : 0,
      ));
    }

    // Build TimePeriodSummary for Today and Tomorrow (6 segments total)
    // 午前: 06:00 - 11:59 (hours 6..11)
    // 午後: 12:00 - 17:59 (hours 12..17)
    // 夜:   18:00 - 23:59 (hours 18..23)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    List<TimePeriodSummary> summaries = [];
    summaries.addAll(_calculatePeriodsForDate(today, "今日", allHourly));
    summaries.addAll(_calculatePeriodsForDate(tomorrow, "明日", allHourly));

    return LocationWeatherData(
      location: location,
      current: current,
      hourly: allHourly,
      daily: allDaily,
      periodSummaries: summaries,
      fetchedAt: fetchedAt,
      isFromCache: isFromCache,
    );
  }

  static List<TimePeriodSummary> _calculatePeriodsForDate(
    DateTime date,
    String dayLabel,
    List<HourlyForecast> hourlyList,
  ) {
    final periods = [
      (short: '午前', label: '午前 (6-12時)', startH: 6, endH: 12),
      (short: '午後', label: '午後 (12-18時)', startH: 12, endH: 18),
      (short: '夜',   label: '夜 (18-24時)', startH: 18, endH: 24),
    ];

    List<TimePeriodSummary> result = [];

    for (final p in periods) {
      final matched = hourlyList.where((h) {
        return h.time.year == date.year &&
            h.time.month == date.month &&
            h.time.day == date.day &&
            h.time.hour >= p.startH &&
            h.time.hour < p.endH;
      }).toList();

      if (matched.isEmpty) {
        result.add(TimePeriodSummary(
          dayLabel: dayLabel,
          periodLabel: p.label,
          periodShort: p.short,
          targetDate: date,
          weatherCode: 0,
          maxPrecipitationProbability: 0,
          maxTemp: 0,
          minTemp: 0,
        ));
        continue;
      }

      int maxPrecip = 0;
      double maxT = matched.first.temperature;
      double minT = matched.first.temperature;

      // Select dominant weather code (prioritize highest code which is usually rain/thunder/snow)
      int dominantCode = matched.first.weatherCode;
      int maxSeverity = 0;

      for (final h in matched) {
        if (h.precipitationProbability > maxPrecip) {
          maxPrecip = h.precipitationProbability;
        }
        if (h.temperature > maxT) maxT = h.temperature;
        if (h.temperature < minT) minT = h.temperature;

        // Severe weather takes priority in summary icon
        final severity = _weatherSeverity(h.weatherCode);
        if (severity > maxSeverity) {
          maxSeverity = severity;
          dominantCode = h.weatherCode;
        }
      }

      result.add(TimePeriodSummary(
        dayLabel: dayLabel,
        periodLabel: p.label,
        periodShort: p.short,
        targetDate: date,
        weatherCode: dominantCode,
        maxPrecipitationProbability: maxPrecip,
        maxTemp: maxT,
        minTemp: minT,
      ));
    }

    return result;
  }

  static int _weatherSeverity(int code) {
    if (code >= 95) return 5; // Thunderstorm
    if (code >= 71) return 4; // Snow
    if (code >= 61 || code >= 80) return 3; // Rain
    if (code >= 51) return 2; // Drizzle
    if (code >= 2) return 1; // Cloudy
    return 0; // Clear
  }
}
