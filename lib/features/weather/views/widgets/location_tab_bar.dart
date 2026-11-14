import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../models/location_config.dart';
import '../../models/weather_code_helper.dart';
import '../../models/weather_data.dart';

class LocationTabBar extends StatelessWidget {
  final List<LocationConfig> locations;
  final int selectedIndex;
  final Map<String, LocationWeatherData> weatherDataMap;
  final ValueChanged<int> onSelectIndex;
  final VoidCallback onAddLocation;

  const LocationTabBar({
    super.key,
    required this.locations,
    required this.selectedIndex,
    required this.weatherDataMap,
    required this.onSelectIndex,
    required this.onAddLocation,
  });

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(3.5),
        decoration: BoxDecoration(
          color: AppColors.slate900.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorderLight, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < locations.length; i++) ...[
                _buildTabItem(
                  index: i,
                  location: locations[i],
                  weatherData: weatherDataMap[locations[i].id],
                ),
                if (i < locations.length - 1) const SizedBox(width: 4),
              ],
              const SizedBox(width: 4),
              // Add Location Button
              InkWell(
                onTap: onAddLocation,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: AppColors.sky400),
                      SizedBox(width: 2),
                      Text(
                        '追加',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sky400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required LocationConfig location,
    required LocationWeatherData? weatherData,
  }) {
    final isSelected = selectedIndex == index;

    IconData? weatherIcon;
    Color? iconColor;
    String? tempText;

    if (weatherData != null) {
      final current = weatherData.current;
      final isNight = current.time.hour < 6 || current.time.hour >= 18;
      final info = WeatherCodeHelper.getInfo(current.weatherCode, isNight: isNight);
      weatherIcon = info.icon;
      iconColor = info.color;
      tempText = '${current.temperature.toStringAsFixed(0)}°';
    }

    return GestureDetector(
      onTap: () => onSelectIndex(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sky400 : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.sky400.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Weather Icon (Today's icon)
            if (weatherIcon != null) ...[
              Icon(
                weatherIcon,
                size: 17,
                color: isSelected ? AppColors.slate950 : (iconColor ?? AppColors.sky400),
              ),
              const SizedBox(width: 6),
            ] else ...[
              Icon(
                Icons.place_rounded,
                size: 15,
                color: isSelected ? AppColors.slate950 : AppColors.slate400,
              ),
              const SizedBox(width: 5),
            ],

            // Custom Display Name
            Text(
              location.name,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.slate950 : AppColors.slate200,
              ),
            ),

            // Temperature pill
            if (tempText != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.black.withValues(alpha: 0.15)
                      : AppColors.slate800,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  tempText,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? AppColors.slate950 : AppColors.slate300,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
