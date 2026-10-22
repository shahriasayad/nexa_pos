import 'package:flutter/material.dart';

import 'package:nexa_pos/core/repositories/app_repositories.dart';
import 'package:nexa_pos/core/state/view_state.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';
import 'package:nexa_pos/core/theme/app_spacing.dart';
import 'package:nexa_pos/features/customers/presentation/controllers/customer_controller.dart';
import 'package:nexa_pos/shared/widgets/custom_button.dart';
import 'package:nexa_pos/shared/widgets/empty_state_view.dart';
import 'package:nexa_pos/shared/widgets/loading_view.dart';

class CustomerSelectionDialog extends StatefulWidget {
  const CustomerSelectionDialog({super.key});

  @override
  State<CustomerSelectionDialog> createState() =>
      _CustomerSelectionDialogState();
}

class _CustomerSelectionDialogState extends State<CustomerSelectionDialog> {
  late CustomerController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = CustomerController(
      repository: AppRepositories.instance.customerRepo,
    );
    _controller.loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(AppRadius.normal),
                        ),
                        child: const Icon(
                          Icons.person_search_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Text(
                        'Select Customer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context, null),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, phone, or email...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _controller.loadCustomers();
                          },
                        )
                      : null,
                ),
                onChanged: (val) => _controller.loadCustomers(query: val),
              ),
              const SizedBox(height: AppSpacing.md),

              // Walk-in Quick Option
              InkWell(
                onTap: () => Navigator.pop(context, 'clear'),
                borderRadius: BorderRadius.circular(AppRadius.normal),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceMuted
                        : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.normal),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.storefront_outlined,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Walk-in Customer (General)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            Text(
                              'No customer profile attached to this transaction',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),

              // Customer List
              Expanded(
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    if (_controller.state == ViewState.loading ||
                        _controller.state == ViewState.initial) {
                      return const LoadingView(message: 'Searching customers...');
                    }
                    if (_controller.state == ViewState.error) {
                      return Center(
                        child: Text(
                          _controller.errorMessage ?? 'Failed to load customers',
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      );
                    }
                    if (_controller.state == ViewState.empty ||
                        _controller.customers.isEmpty) {
                      return const EmptyStateView(
                        icon: Icons.person_off_outlined,
                        title: 'No Customers Found',
                        description: 'Try adjusting your search criteria.',
                      );
                    }

                    return ListView.separated(
                      itemCount: _controller.customers.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final customer = _controller.customers[index];
                        final initials = customer.name.isNotEmpty
                            ? customer.name
                                .trim()
                                .split(' ')
                                .take(2)
                                .map((e) => e.isNotEmpty ? e[0] : '')
                                .join()
                                .toUpperCase()
                            : '?';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primarySoft,
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: AppColors.primaryStrong,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(
                            customer.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            [
                              if (customer.phone != null &&
                                  customer.phone!.isNotEmpty)
                                customer.phone!,
                              if (customer.email != null &&
                                  customer.email!.isNotEmpty)
                                customer.email!,
                            ].join(' • '),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                          ),
                          onTap: () => Navigator.pop(context, customer),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomButton(
                    label: 'Close',
                    variant: CustomButtonVariant.outline,
                    height: 38,
                    onPressed: () => Navigator.pop(context, null),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
