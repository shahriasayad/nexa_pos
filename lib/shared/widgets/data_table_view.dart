import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/shared/widgets/custom_card.dart';

class PosTableColumn {
  final String label;
  final int flex;
  final double? width;
  final TextAlign alignment;

  const PosTableColumn({
    required this.label,
    this.flex = 1,
    this.width,
    this.alignment = TextAlign.left,
  });
}

class PosDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final Widget? emptyWidget;
  final EdgeInsetsGeometry padding;
  final double? minWidth;

  const PosDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.emptyWidget,
    this.padding = EdgeInsets.zero,
    this.minWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (rows.isEmpty && emptyWidget != null) {
      return emptyWidget!;
    }

    return CustomCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.normal),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: minWidth ?? MediaQuery.of(context).size.width - 320,
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.resolveWith(
                (states) => isDark
                    ? AppColors.darkSurfaceMuted
                    : AppColors.surfaceMuted,
              ),
              headingTextStyle: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              dataTextStyle: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              dividerThickness: 1,
              horizontalMargin: AppSpacing.lg,
              columnSpacing: AppSpacing.xl,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 64,
              columns: columns,
              rows: rows,
            ),
          ),
        ),
      ),
    );
  }
}
