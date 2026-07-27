import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';

/// Розкривний блок "Додаткові параметри" внизу форми — той самий паттерн,
/// що й у ліках/нагадуваннях, лише вміст ([children]) відрізняється.
class MoreDetailsAccordion extends StatefulWidget {
  final List<Widget> children;
  final bool initiallyExpanded;

  const MoreDetailsAccordion({
    super.key,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  State<MoreDetailsAccordion> createState() => _MoreDetailsAccordionState();
}

class _MoreDetailsAccordionState extends State<MoreDetailsAccordion> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, size: 18, color: AppColors.textSub),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.optionalParamsLabel,
                    style: AppTextStyles.labelMd.copyWith(color: AppColors.textSub),
                  ),
                ),
                Text(
                  context.l10n.optionalLabel,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.children,
            ),
          ),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
