import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 0=xs 1=sm(за замовчуванням) 2=md 3=lg
const List<double> fontScaleValues = [0.85, 1.0, 1.15, 1.3];

class FontSizeIndexNotifier extends StateNotifier<int> {
  FontSizeIndexNotifier() : super(1) {
    _load();
  }

  static const _key = 'font_size_index';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_key);
    if (saved != null) state = saved;
  }

  Future<void> setIndex(int index) async {
    state = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, index);
  }
}

final fontSizeIndexProvider =
    StateNotifierProvider<FontSizeIndexNotifier, int>(
        (ref) => FontSizeIndexNotifier());
