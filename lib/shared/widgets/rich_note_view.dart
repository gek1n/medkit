import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/rich_note_format.dart';

/// Рендер тексту з форматуванням (RichNoteBlock-и з rich_note_format.dart) —
/// Ліки/Нагадування/Полички разом використовують один і той самий парсер,
/// цей віджет — спільний рендер. [onToggleChecklistLine] не null → чекбокси
/// клікабельні (лише для власних локальних записів, див. виклик у
/// MedcardEntryViewScreen); null → статичний перегляд (чужий/піровий запис).
class RichNoteView extends StatelessWidget {
  final String raw;
  final TextStyle? baseStyle;
  final void Function(int lineIndex)? onToggleChecklistLine;

  const RichNoteView({
    super.key,
    required this.raw,
    this.baseStyle,
    this.onToggleChecklistLine,
  });

  @override
  Widget build(BuildContext context) {
    final base = baseStyle ?? AppTextStyles.bodyMd;
    final blocks = parseRichNote(raw);
    final children = <Widget>[];
    for (var i = 0; i < blocks.length; i++) {
      if (i > 0) children.add(const SizedBox(height: 8));
      children.add(_buildBlock(blocks[i], base));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _buildBlock(RichNoteBlock block, TextStyle base) {
    switch (block) {
      case RichParagraphBlock(:final text):
        if (text.isEmpty) return const SizedBox(height: 4);
        return RichText(text: TextSpan(children: buildInlineSpans(text, base)));

      case RichChecklistBlock(:final items):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggleChecklistLine == null
                      ? null
                      : () => onToggleChecklistLine!(item.lineIndex),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 19,
                        height: 19,
                        margin: const EdgeInsets.only(top: 1.5, right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: item.checked ? AppColors.primary : Colors.transparent,
                          border: Border.all(
                            color: item.checked ? AppColors.primary : AppColors.textMuted,
                            width: 1.6,
                          ),
                        ),
                        child: item.checked
                            ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                            : null,
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: buildInlineSpans(
                              item.text,
                              item.checked
                                  ? base.copyWith(
                                      color: AppColors.textMuted, decoration: TextDecoration.lineThrough)
                                  : base,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );

      case RichBulletListBlock(:final items):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ', style: base.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w800)),
                    Expanded(child: RichText(text: TextSpan(children: buildInlineSpans(item.text, base)))),
                  ],
                ),
              ),
          ],
        );

      case RichNumberedListBlock(:final items):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${i + 1}.  ', style: base.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w800)),
                    Expanded(child: RichText(text: TextSpan(children: buildInlineSpans(items[i].text, base)))),
                  ],
                ),
              ),
          ],
        );

      case RichQuoteBlock(:final text):
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            border: const Border(left: BorderSide(color: AppColors.accent, width: 3)),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(AppDimensions.radiusMd),
              bottomRight: Radius.circular(AppDimensions.radiusMd),
            ),
          ),
          child: RichText(
            text: TextSpan(children: buildInlineSpans(text, base.copyWith(fontStyle: FontStyle.italic))),
          ),
        );
    }
  }
}
