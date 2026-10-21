import 'package:flutter/material.dart';
import 'package:nexa_pos/shared/widgets/kpi_card.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final String? subtitle;
  final bool isHero;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.subtitle,
    this.isHero = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PosKpiCard(
      title: title,
      value: value,
      icon: icon,
      iconColor: iconColor,
      subtitle: subtitle,
      isHero: isHero,
      onTap: onTap,
    );
  }
}
