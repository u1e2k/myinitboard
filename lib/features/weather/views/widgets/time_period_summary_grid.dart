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

    final todayList = summaries.take(3).toList();
    final tomorrowList = summaries.skip(3).take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader('今日', Icons.today_rounded, const Color(0xFF38BDF8)),
        const SizedBox(height: 6),
        _buildRow(todayList),
        const SizedBox(height: 10),
        _buildSectionHeader('明日', Icons.event_rounded, const Color(0xFF818CF8)),
        const SizedBox(height: 6),
        _buildRow(tomorrowList),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color accentColor) {
    return Row(
      children: [
        Icon(icon, size: 13, color: accentColor),
        const SizedBox(width: 5),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.slate300,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '（午前 6-12時 / 午後 12-18時 / 夜 18-24時）',
          style: TextStyle(
            fontSize: 10.5,
            color: AppColors.slate500,
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isRainAlert
              ? [
                  const Color(0xFF0C2B47),
                  const Color(0xFF081C30),
                ]
              : [
                  const Color(0xFF1E283D),
                  const Color(0xFF131B2B),
                ],
        ),
        border: Border.all(
          color: isRainAlert ? AppColors.sky400 : AppColors.glassBorderLight,
          width: isRainAlert ? 1.2 : 0.8,
        ),
        boxShadow: isRainAlert
            ? [
                BoxShadow(
                  color: AppColors.sky500.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Period Label & Rain Indicator Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.periodShort,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isRainAlert ? AppColors.sky300 : AppColors.slate300,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isRainAlert
                      ? AppColors.sky500.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.water_drop,
                      size: 9.5,
                      color: isRainAlert ? AppColors.sky400 : AppColors.slate400,
                    ),
                    const SizedBox(width: 1.5),
                    Text(
                      '${item.maxPrecipitationProbability}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isRainAlert ? FontWeight.w800 : FontWeight.w500,
                        color: isRainAlert ? AppColors.sky300 : AppColors.slate400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Weather Icon with soft glowing background
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: info.color.withValues(alpha: 0.1),
            ),
            child: Icon(info.icon, size: 22, color: info.color),
          ),
          const SizedBox(height: 5),

          // Weather Label
          Text(
            info.label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.slate200,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
