import 'package:flutter/material.dart';

/// Нейтральний набір іконок для довільних розділів архіву — навмисно без
/// жодної медичної символіки (хрестів, таблеток, шприців тощо), щоб розділ
/// міг бути чим завгодно: колекцією, побутовими нотатками, збереженими
/// документами. Зберігається як рядковий ключ (не codePoint напряму) —
/// стійкіше до tree-shaking шрифту іконок при релізній збірці.
const Map<String, IconData> medcardIcons = {
  'folder': Icons.folder_rounded,
  'star': Icons.star_rounded,
  'home': Icons.home_rounded,
  'car': Icons.directions_car_rounded,
  'pet': Icons.pets_rounded,
  'book': Icons.menu_book_rounded,
  'gift': Icons.card_giftcard_rounded,
  'briefcase': Icons.work_rounded,
  'tools': Icons.build_rounded,
  'plant': Icons.eco_rounded,
  'music': Icons.music_note_rounded,
  'camera': Icons.photo_camera_rounded,
  'travel': Icons.flight_rounded,
  'food': Icons.restaurant_rounded,
  'shopping': Icons.shopping_bag_rounded,
  'sport': Icons.sports_basketball_rounded,
  'kids': Icons.child_friendly_rounded,
  'finance': Icons.savings_rounded,
  'document': Icons.description_rounded,
  'calendar': Icons.event_rounded,
  'idea': Icons.lightbulb_rounded,
  'heart': Icons.favorite_rounded,
  'tag': Icons.sell_rounded,
  'box': Icons.inventory_2_rounded,
};

const String defaultMedcardIconKey = 'folder';

IconData medcardIconFor(String key) => medcardIcons[key] ?? medcardIcons[defaultMedcardIconKey]!;
