import 'package:flutter/material.dart';

/// Повнокольорова іконка-ілюстрація в стилі Еллі з assets/icons/ — для
/// фіксованих (не user-generated) наборів ключів: типи завдань у пікері,
/// типи повтору нагадування, форми ліків. Для розділів Простору (де ключ
/// приходить з БД і потребує фолбеку на невалідні значення) — див.
/// MedcardIcon у core/utils/medcard_icons.dart.
class AssetIcon extends StatelessWidget {
  final String assetKey;
  final double size;
  const AssetIcon(this.assetKey, {super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/icons/$assetKey.png', width: size, height: size, fit: BoxFit.contain);
  }
}
