import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../features/today/providers/today_providers.dart';

/// Показується на всіх головних вкладках, коли активний профіль (через
/// перемикач у Сім'ї/Сьогодні) — не власник застосунку. Дає змогу одним
/// дотиком повернутись на свій профіль.
class SwitchProfileBanner extends ConsumerWidget {
  final String name;
  /// За замовчуванням скидає глобальний activeMemberIdProvider (Сьогодні/
  /// Сім'я/Профіль). Передай свій колбек, якщо екран керує вибором члена
  /// сім'ї власним локальним станом (як-от Розклад).
  final VoidCallback? onReturn;
  const SwitchProfileBanner({super.key, required this.name, this.onReturn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFED7AA), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.visibility_rounded, size: 16, color: Color(0xFF92400E)),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Ви дивитесь профіль: $name',
                  style: AppTextStyles.bodySm.copyWith(
                      color: const Color(0xFF92400E),
                      fontWeight: FontWeight.w600)),
            ),
            GestureDetector(
              onTap: onReturn ??
                  () => ref.read(activeMemberIdProvider.notifier).state = null,
              child: Text('Повернутись',
                  style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

/// true, коли переглядається профіль не-власника через активний перемикач.
bool shouldShowSwitchBanner(int? activeMemberId, String memberRole) =>
    activeMemberId != null && memberRole != 'owner';
