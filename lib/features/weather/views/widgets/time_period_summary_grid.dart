import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../models/weather_code_helper.dart';
import '../../models/weather_data.dart';

class TimePeriodSummaryGrid extends StatelessWidget {
  final List<TimePeriodSummary> summaries;
  final bool isLandscape;

  const TimePeriodSummaryGrid({
    super.key,
    required this.summaries,
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) return const SizedBox.shrink();

    // Split into Today (first 3) and Tomorrow (next 3)
    final todayList = summaries.take(3).toList();
    final tomorrowList = summaries.skip(3).take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader('今日（午前 / 午後 / 夜）'),
        const SizedBox(height: 6),
        _buildRow(todayList),
        const SizedBox(height: 10),
        _buildSectionHeader('明日（午前 / 午後 / 夜）'),
        const SizedBox(height: 6),
        _buildRow(tomorrowList),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.slate400,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildRow(List<TimePeriodSummary> items) {
    return Row(
      children: items.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _buildItemCard(item),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildItemCard(TimePeriodSummary item) {
    final isRainAlert = item.isRainHigh;
    final isNight = item.periodShort == '夜';
    final info = WeatherCodeHelper.getInfo(item.weatherCode, isNight: isNight);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isRainAlert ? AppColors.rainHighBg : AppColors.slate800,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRainAlert ? AppColors.rainHighBorder : AppColors.slate700,
          width: isRainAlert ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Period Label (午前 / 午後 / 夜)
          Text(
            item.periodShort,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isRainAlert ? AppColors.sky400 : AppColors.slate300,
            ),
          ),
          const SizedBox(height: 4),
          // Weather Icon
          Icon(
            info.icon,
            size: 22,
            color: info.color,
          ),
          const SizedBox(height: 4),
          // Weather Label
          Text(
            info.label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.slate300,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Rain probability & Temp
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.water_drop,
                size: 11,
                color: isRainAlert ? AppColors.sky400 : AppColors.slate500,
              ),
              const SizedBox(width: 2),
              Text(
                '${item.maxPrecipitationProbability}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isRainAlert ? FontWeight.bold : FontWeight.normal,
                  color: isRainAlert ? AppColors.sky400 : AppColors.slate400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
