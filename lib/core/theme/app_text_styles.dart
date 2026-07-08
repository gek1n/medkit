import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static TextStyle h1 = GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textMain, height: 1.2);
  static TextStyle h2 = GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textMain, height: 1.3);
  static TextStyle h3 = GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textMain, height: 1.4);
  static TextStyle bodyLg = GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textMain, height: 1.5);
  static TextStyle bodyMd = GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textMain, height: 1.5);
  static TextStyle bodySm = GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSub, height: 1.5);
  static TextStyle labelLg = GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textMain);
  static TextStyle labelMd = GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMain);
  static TextStyle labelSm = GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.6);
  static TextStyle caption = GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textMuted, height: 1.4);
}
