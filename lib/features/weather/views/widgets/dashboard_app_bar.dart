import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme.dart';

class DashboardAppBar extends StatelessWidget {
  final DateTime? latestFetchTime;
  final bool isAnyFromCache;
  final bool isLoading;
  final VoidCallback onRefresh;
  final VoidCallback onOpenSettings;

  const DashboardAppBar({
    super.key,
    required this.latestFetchTime,
    required this.isAnyFromCache,
    required this.isLoading,
    required this.onRefresh,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = latestFetchTime != null
        ? DateFormat('MM/dd HH:mm').format(latestFetchTime!)
        : '--:--';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.glassBorder, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          // App Logo & Title
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF38BDF8), Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: AppColors.sky400.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 9),
          const Text(
            'myinitboard',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              letterSpacing: -0.2,
              color: AppColors.slate50,
            ),
          ),
          const Spacer(),

          // Status & Last fetch time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: isAnyFromCache ? AppColors.offlineBg : AppColors.glassSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isAnyFromCache
                    ? AppColors.offlineText.withValues(alpha: 0.4)
                    : AppColors.glassBorderLight,
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6.5,
                  height: 6.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isAnyFromCache ? AppColors.offlineText : const Color(0xFF34D399),
                    boxShadow: [
                      BoxShadow(
                        color: (isAnyFromCache ? AppColors.offlineText : const Color(0xFF34D399))
                            .withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isAnyFromCache ? 'オフライン ($timeStr)' : '同期: $timeStr',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isAnyFromCache ? AppColors.offlineText : AppColors.slate300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Refresh Button
          IconButton(
            tooltip: '全地点を再取得',
            onPressed: isLoading ? null : onRefresh,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.glassSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
                side: const BorderSide(color: AppColors.glassBorder, width: 0.8),
              ),
              padding: const EdgeInsets.all(7),
            ),
            icon: isLoading
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sky400),
                  )
                : const Icon(Icons.refresh_rounded, color: AppColors.slate200, size: 17),
          ),
          const SizedBox(width: 5),

          // Settings Button
          IconButton(
            tooltip: '登録地点の管理・設定',
            onPressed: onOpenSettings,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.glassSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
                side: const BorderSide(color: AppColors.glassBorder, width: 0.8),
              ),
              padding: const EdgeInsets.all(7),
            ),
            icon: const Icon(Icons.settings_outlined, color: AppColors.slate200, size: 17),
          ),
        ],
      ),
    );
  }
}
