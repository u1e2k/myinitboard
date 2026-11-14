import 'package:flutter/material.dart';

class WeatherCodeInfo {
  final String label;
  final IconData icon;
  final Color color;

  const WeatherCodeInfo({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class WeatherCodeHelper {
  static WeatherCodeInfo getInfo(int code, {bool isNight = false}) {
    switch (code) {
      case 0:
        return WeatherCodeInfo(
          label: isNight ? '快晴（夜）' : '快晴',
          icon: isNight ? Icons.nightlight_round : Icons.wb_sunny_rounded,
          color: isNight ? const Color(0xFFFDE047) : const Color(0xFFFBBF24),
        );
      case 1:
        return WeatherCodeInfo(
          label: isNight ? 'ほぼ快晴' : '概ね晴れ',
          icon: isNight ? Icons.nightlight_round : Icons.wb_sunny_outlined,
          color: isNight ? const Color(0xFFFDE047) : const Color(0xFFFBBF24),
        );
      case 2:
        return WeatherCodeInfo(
          label: '晴れ時々曇り',
          icon: isNight ? Icons.cloud_queue : Icons.wb_cloudy_rounded,
          color: const Color(0xFF93C5FD),
        );
      case 3:
        return const WeatherCodeInfo(
          label: 'くもり',
          icon: Icons.cloud_rounded,
          color: Color(0xFF94A3B8),
        );
      case 45:
      case 48:
        return const WeatherCodeInfo(
          label: '霧',
          icon: Icons.blur_on_rounded,
          color: Color(0xFF94A3B8),
        );
      case 51:
      case 53:
      case 55:
        return const WeatherCodeInfo(
          label: '霧雨',
          icon: Icons.grain_rounded,
          color: Color(0xFF67E8F9),
        );
      case 56:
      case 57:
        return const WeatherCodeInfo(
          label: '着氷性の霧雨',
          icon: Icons.ac_unit_rounded,
          color: Color(0xFFA5F3FC),
        );
      case 61:
        return const WeatherCodeInfo(
          label: '小雨',
          icon: Icons.water_drop_outlined,
          color: Color(0xFF38BDF8),
        );
      case 63:
        return const WeatherCodeInfo(
          label: '雨',
          icon: Icons.water_drop_rounded,
          color: Color(0xFF0284C7),
        );
      case 65:
        return const WeatherCodeInfo(
          label: '大雨',
          icon: Icons.thunderstorm_outlined,
          color: Color(0xFF0369A1),
        );
      case 66:
      case 67:
        return const WeatherCodeInfo(
          label: '着氷性の雨',
          icon: Icons.ac_unit_rounded,
          color: Color(0xFF7DD3FC),
        );
      case 71:
        return const WeatherCodeInfo(
          label: '小雪',
          icon: Icons.cloudy_snowing,
          color: Color(0xFFE2E8F0),
        );
      case 73:
        return const WeatherCodeInfo(
          label: '雪',
          icon: Icons.ac_unit_rounded,
          color: Color(0xFFE2E8F0),
        );
      case 75:
        return const WeatherCodeInfo(
          label: '大雪',
          icon: Icons.ac_unit_rounded,
          color: Color(0xFFF8FAFC),
        );
      case 77:
        return const WeatherCodeInfo(
          label: '雪あられ',
          icon: Icons.grain_rounded,
          color: Color(0xFFE2E8F0),
        );
      case 80:
        return const WeatherCodeInfo(
          label: '弱い通り雨',
          icon: Icons.grain_rounded,
          color: Color(0xFF38BDF8),
        );
      case 81:
        return const WeatherCodeInfo(
          label: '通り雨',
          icon: Icons.water_drop_rounded,
          color: Color(0xFF0284C7),
        );
      case 82:
        return const WeatherCodeInfo(
          label: '激しい通り雨',
          icon: Icons.thunderstorm_rounded,
          color: Color(0xFF0284C7),
        );
      case 85:
      case 86:
        return const WeatherCodeInfo(
          label: 'にわか雪',
          icon: Icons.cloudy_snowing,
          color: Color(0xFFE2E8F0),
        );
      case 95:
        return const WeatherCodeInfo(
          label: '雷雨',
          icon: Icons.bolt_rounded,
          color: Color(0xFFFBBF24),
        );
      case 96:
      case 99:
        return const WeatherCodeInfo(
          label: '雹を伴う雷雨',
          icon: Icons.bolt_rounded,
          color: Color(0xFFF87171),
        );
      default:
        return const WeatherCodeInfo(
          label: '不明',
          icon: Icons.help_outline_rounded,
          color: Color(0xFF64748B),
        );
    }
  }
}
