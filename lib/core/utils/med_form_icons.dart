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
