import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';

import '../../domain/models/dashboard_metrics.dart';

class SalesChart extends StatelessWidget {
  final DashboardMetrics metrics;

  const SalesChart({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final data = metrics.chartData.isEmpty ? [0.0] : metrics.chartData;
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final totalRevenue = data.fold(0.0, (sum, val) => sum + val);

    final List<String> labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue Trend',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Daily breakdown for current period',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${totalRevenue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Period Total',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Chart area
          SizedBox(
            height: 190,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.length, (index) {
                final value = data[index];
                final heightFactor = maxValue == 0 ? 0.0 : (value / maxValue);
                final barHeight = (140 * heightFactor).clamp(8.0, 140.0);
                final label = index < labels.length ? labels[index] : 'P${index + 1}';

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Tooltip(
                          message: '\$${value.toStringAsFixed(2)}',
                          child: Container(
                            height: barHeight,
                            constraints: const BoxConstraints(maxWidth: 36),
                            decoration: BoxDecoration(
                              color: value == maxValue && maxValue > 0
                                  ? (isDark ? AppColors.darkSuccess : AppColors.primary)
                                  : (isDark
                                      ? AppColors.darkSurfaceMuted
                                      : AppColors.primarySoft),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                              border: Border.all(
                                color: (isDark ? AppColors.darkSuccess : AppColors.primary)
                                    .withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
