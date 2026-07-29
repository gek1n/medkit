import 'package:flutter/material.dart';

/// Нейтральний набір іконок для довільних розділів архіву — навмисно без
/// жодної медичної символіки (хрестів, таблеток, шприців тощо), щоб розділ
/// міг бути чим завгодно: колекцією, побутовими нотатками, збереженими
/// документами. Зберігається як рядковий ключ — стійкіше до перейменувань,
/// ніж прямий codePoint/шлях.
///
/// Раніше тут був набір Material IconData, що тонувався в колір розділу.
/// Тепер кожен ключ має власну повнокольорову ілюстрацію в стилі Еллі
/// (assets/icons/`key`.png) — колір розділу передається через фон-підложку
/// навколо іконки (у місцях використання), а не через тонування самої
/// картинки.
const List<String> medcardIconKeys = [
  'folder',
  'star',
  'home',
  'car',
  'pet',
  'book',
  'gift',
  'briefcase',
  'tools',
  'plant',
  'music',
  'camera',
  'travel',
  'food',
  'shopping',
  'sport',
  'kids',
  'finance',
  'document',
  'calendar',
  'idea',
  'heart',
  'tag',
  'box',
  'antistress',
  'backup',
  'brain',
  'family',
  'eye',
  'excercise',
  'cleaning',
  'form_cream',
  'plans',
  'repeat_yearly',
  'sleep',
  'task_routine',
  'task_note',
  // Колишні "форми випуску ліків" — приєднані після стандартного набору
  // (той самий assets/icons/form_*.png), щоб один спільний пікер
  // (showMedcardIconPicker) працював і для карток Полички/рутин, і для
  // Інвентарю. Явно медичні варіанти (таблетка, свічка, інгалятор, шприц)
  // та стетоскоп/лікар прибрані — App Store review не дозволяє явну
  // медичну символіку.
  'form_vial',
  'form_syrup',
  'form_drops',
  'form_cream',
];

const String defaultMedcardIconKey = 'folder';

String medcardIconAssetFor(String key) =>
    'assets/icons/${medcardIconKeys.contains(key) ? key : defaultMedcardIconKey}.png';

/// Готовий віджет-іконка розділу — повнокольорове зображення без
/// додаткового тонування (колір розділу відображається фоном навколо, не
/// самою картинкою).
class MedcardIcon extends StatelessWidget {
  final String iconKey;
  final double size;
  const MedcardIcon(this.iconKey, {super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Image.asset(medcardIconAssetFor(iconKey), width: size, height: size, fit: BoxFit.contain);
  }
}
