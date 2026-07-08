import 'package:flutter/material.dart';

/// Палітра для кастомного кольору картки завдання (ліки/лікар/активність/
/// самопочуття) — зберігається як hex-рядок "#RRGGBB", null = дефолтний
/// колір типу завдання.
const List<String> taskColorPalette = [
  '#F5A65C',
  '#6AAF8B',
  '#E8735A',
  '#A58BC9',
  '#72A8C7',
  '#FF9B9B',
  '#8AC5F5',
  '#FFC168',
];

Color? colorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  final cleaned = hex.replaceFirst('#', '');
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}
