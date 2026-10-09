import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';
import 'package:nexa_pos/shared/widgets/section_header.dart';

import '../../domain/models/dashboard_metrics.dart';

class SalesChart extends StatelessWidget {
  final DashboardMetrics metrics;

  const SalesChart({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Sales Overview'),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 220,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: metrics.chartData.map((value) {
                // Simple proportional bar
                final maxValue = metrics.chartData.reduce(
                  (a, b) => a > b ? a : b,
                );
                final heightFactor = maxValue == 0 ? 0.0 : value / maxValue;

                return Tooltip(
                  message: '\$${value.toStringAsFixed(2)}',
                  child: Container(
                    width: 32,
                    height: (220 * heightFactor).clamp(
                      4.0,
                      220.0,
                    ), // Minimum height of 4.0
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
