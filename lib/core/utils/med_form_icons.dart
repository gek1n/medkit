import 'package:flutter/material.dart';

IconData medFormIcon(String form) => switch (form) {
      'syrup' => Icons.local_drink_rounded,
      'drops' => Icons.water_drop_rounded,
      'cream' => Icons.spa_rounded,
      'inhaler' => Icons.air_rounded,
      'injection' => Icons.vaccines_rounded,
      'vial' => Icons.science_rounded,
      'suppository' => Icons.egg_rounded,
      _ => Icons.medication_rounded,
    };

// Ключ повнокольорової ілюстрації форми випуску (assets/icons/form_*.png,
// стиль Еллі) — див. AssetIcon.
String medFormIconAsset(String form) => switch (form) {
      'syrup' => 'form_syrup',
      'drops' => 'form_drops',
      'cream' => 'form_cream',
      'inhaler' => 'form_inhaler',
      'injection' => 'form_injection',
      'vial' => 'form_vial',
      'suppository' => 'form_suppository',
      _ => 'form_tablet',
    };
