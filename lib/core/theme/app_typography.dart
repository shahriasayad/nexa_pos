import 'package:flutter/material.dart';
import 'package:nexa_pos/core/theme/app_colors.dart';

class AppTypography {
  static const String fontFamily =
      'Inter'; // A clean sans-serif like Inter or Roboto

  // Light Theme TextStyles
  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle pageTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle secondary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle financial = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Dark Theme TextStyles
  static const TextStyle darkDisplay = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.darkTextPrimary,
  );

  static const TextStyle darkPageTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.darkTextPrimary,
  );

  static const TextStyle darkSectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.darkTextPrimary,
  );

  static const TextStyle darkBody = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.darkTextPrimary,
  );

  static const TextStyle darkBodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.darkTextPrimary,
  );

  static const TextStyle darkSecondary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.darkTextSecondary,
  );

  static const TextStyle darkFinancial = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.darkTextPrimary,
  );
}
