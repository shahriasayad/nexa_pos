import 'package:flutter/material.dart';
import '../../domain/models/dashboard_metrics.dart';

class SalesChart extends StatelessWidget {
  final DashboardMetrics metrics;

  const SalesChart({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: metrics.chartData.map((value) {
                  // Simple proportional bar
                  final maxValue = metrics.chartData.reduce((a, b) => a > b ? a : b);
                  final heightFactor = maxValue == 0 ? 0.0 : value / maxValue;
                  
                  return Tooltip(
                    message: '\$${value.toStringAsFixed(2)}',
                    child: Container(
                      width: 24,
                      height: 200 * heightFactor,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
