import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textMain,
        height: 1.2,
      );

  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textMain,
        height: 1.3,
      );

  static TextStyle get h3 => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textMain,
        height: 1.3,
      );

  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textMain,
        height: 1.5,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSub,
        height: 1.5,
      );

  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        height: 1.4,
      );

  static TextStyle get labelLg => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textMain,
      );

  static TextStyle get labelMd => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textMain,
      );

  static TextStyle get labelSm => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSub,
        letterSpacing: 0.3,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      );
}
