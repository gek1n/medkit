import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static TextStyle h1 = GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textMain, height: 1.2);
  static TextStyle h2 = GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textMain, height: 1.3);
  static TextStyle h3 = GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textMain, height: 1.4);
  static TextStyle bodyLg = GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textMain, height: 1.5);
  static TextStyle bodyMd = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textMain, height: 1.5);
  static TextStyle bodySm = GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSub, height: 1.5);
  static TextStyle labelLg = GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textMain);
  static TextStyle labelMd = GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMain);
  static TextStyle labelSm = GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.6);
  static TextStyle caption = GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textMuted, height: 1.4);
}
