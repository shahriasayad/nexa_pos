import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/shared/widgets/responsive_layout.dart';

class PosFilterToolbar extends StatefulWidget {
  final TextEditingController? searchController;
  final String? searchValue;
  final String searchHint;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchClear;
  final VoidCallback? onClearSearch;
  final List<Widget>? filterControls;
  final List<Widget>? filters;
  final EdgeInsetsGeometry padding;

  const PosFilterToolbar({
    super.key,
    this.searchController,
    this.searchValue,
    this.searchHint = 'Search...',
    this.onSearchChanged,
    this.onSearchClear,
    this.onClearSearch,
    this.filterControls,
    this.filters,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 0,
      vertical: AppSpacing.xs,
    ),
  });

  @override
  State<PosFilterToolbar> createState() => _PosFilterToolbarState();
}

class _PosFilterToolbarState extends State<PosFilterToolbar> {
  TextEditingController? _internalController;

  TextEditingController get _effectiveController {
    if (widget.searchController != null) return widget.searchController!;
    _internalController ??= TextEditingController(text: widget.searchValue ?? '');
    return _internalController!;
  }

  @override
  void didUpdateWidget(PosFilterToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchController == null &&
        widget.searchValue != null &&
        _internalController != null &&
        _internalController!.text != widget.searchValue) {
      _internalController!.text = widget.searchValue!;
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = ResponsiveLayout.isMobile(context);
    final activeFilters = widget.filters ?? widget.filterControls;
    final clearCallback = widget.onClearSearch ?? widget.onSearchClear;

    final controller = _effectiveController;

    Widget searchField = SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13.5),
        decoration: InputDecoration(
          hintText: widget.searchHint,
          hintStyle: TextStyle(
            fontSize: 13.5,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 18,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          ),
          suffixIcon: controller.text.isNotEmpty || clearCallback != null
              ? IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    controller.clear();
                    clearCallback?.call();
                    widget.onSearchChanged?.call('');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 0,
          ),
          filled: true,
          fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.normal),
            borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.normal),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
        onChanged: widget.onSearchChanged,
      ),
    );

    if (isMobile) {
      return Padding(
        padding: widget.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            searchField,
            if (activeFilters != null && activeFilters.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: activeFilters.map((w) {
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: w,
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: widget.padding,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: searchField,
          ),
          if (activeFilters != null && activeFilters.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.md),
            ...activeFilters.map((w) {
              return Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: w,
              );
            }),
          ],
        ],
      ),
    );
  }
}
