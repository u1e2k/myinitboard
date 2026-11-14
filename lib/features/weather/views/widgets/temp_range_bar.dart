import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

/// iOS 天気アプリ風の気温レンジバー
/// 週間予報の最低・最高気温を基準に、当日の気温幅をグラデーションバーで視覚化します
class TempRangeBar extends StatelessWidget {
  final double min;
  final double max;
  final double overallMin;
  final double overallMax;

  const TempRangeBar({
    super.key,
    required this.min,
    required this.max,
    required this.overallMin,
    required this.overallMax,
  });

  @override
  Widget build(BuildContext context) {
    final range = overallMax - overallMin;
    final leftPercent = ((min - overallMin) / range).clamp(0.0, 1.0);
    final widthPercent = ((max - min) / range).clamp(0.12, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final leftOffset = leftPercent * totalWidth;
        final barWidth = math.min(widthPercent * totalWidth, totalWidth - leftOffset);

        return Container(
          height: 5,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Stack(
            children: [
              Positioned(
                left: leftOffset,
                width: math.max(barWidth, 6.0),
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.tempCold,
                        AppColors.tempMild,
                        AppColors.tempWarm,
                        AppColors.tempHot,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
