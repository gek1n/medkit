import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Легкий Markdown-подібний формат для поля `notes` (MedcardEntries/
/// Reminders) — без нової колонки БД, без стороннього rich-text пакета.
/// Синтаксис по рядках:
///   `[ ] текст` / `[x] текст` — пункт чеклиста (не/позначений)
///   `- текст`                  — маркований список
///   `1. текст`                 — нумерований список (число при збереженні
///                                довільне, при показі перенумеровується)
///   `> текст`                  — цитата
/// Інлайн у межах будь-якого рядка: `**жирний**`, `*курсив*`, `__підкреслений__`.

sealed class RichNoteBlock {
  const RichNoteBlock();
}

class RichParagraphBlock extends RichNoteBlock {
  final String text;
  const RichParagraphBlock(this.text);
}

class RichChecklistItem {
  final String text;
  final bool checked;
  final int lineIndex;
  const RichChecklistItem({required this.text, required this.checked, required this.lineIndex});
}

class RichChecklistBlock extends RichNoteBlock {
  final List<RichChecklistItem> items;
  const RichChecklistBlock(this.items);
}

class RichListItem {
  final String text;
  final int lineIndex;
  const RichListItem({required this.text, required this.lineIndex});
}

class RichBulletListBlock extends RichNoteBlock {
  final List<RichListItem> items;
  const RichBulletListBlock(this.items);
}

class RichNumberedListBlock extends RichNoteBlock {
  final List<RichListItem> items;
  const RichNumberedListBlock(this.items);
}

class RichQuoteBlock extends RichNoteBlock {
  final String text;
  const RichQuoteBlock(this.text);
}

final RegExp _checklistLine = RegExp(r'^\[( |x|X)\]\s?(.*)$');
final RegExp _numberedLine = RegExp(r'^\d+\.\s?(.*)$');
final RegExp _bulletLine = RegExp(r'^-\s?(.*)$');
final RegExp _quoteLine = RegExp(r'^>\s?(.*)$');

List<RichNoteBlock> parseRichNote(String raw) {
  final lines = raw.split('\n');
  final blocks = <RichNoteBlock>[];
  List<RichChecklistItem>? checklist;
  List<RichListItem>? bullets;
  List<RichListItem>? numbered;

  void flushChecklist() {
    if (checklist != null) {
      blocks.add(RichChecklistBlock(checklist!));
      checklist = null;
    }
  }

  void flushBullets() {
    if (bullets != null) {
      blocks.add(RichBulletListBlock(bullets!));
      bullets = null;
    }
  }

  void flushNumbered() {
    if (numbered != null) {
      blocks.add(RichNumberedListBlock(numbered!));
      numbered = null;
    }
  }

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    final chk = _checklistLine.firstMatch(line);
    if (chk != null) {
      flushBullets();
      flushNumbered();
      (checklist ??= []).add(RichChecklistItem(
        text: chk.group(2) ?? '',
        checked: chk.group(1)!.toLowerCase() == 'x',
        lineIndex: i,
      ));
      continue;
    }
    flushChecklist();

    final bullet = _bulletLine.firstMatch(line);
    if (bullet != null) {
      flushNumbered();
      (bullets ??= []).add(RichListItem(text: bullet.group(1) ?? '', lineIndex: i));
      continue;
    }
    flushBullets();

    final num = _numberedLine.firstMatch(line);
    if (num != null) {
      (numbered ??= []).add(RichListItem(text: num.group(1) ?? '', lineIndex: i));
      continue;
    }
    flushNumbered();

    final quote = _quoteLine.firstMatch(line);
    if (quote != null) {
      blocks.add(RichQuoteBlock(quote.group(1) ?? ''));
      continue;
    }

    blocks.add(RichParagraphBlock(line));
  }
  flushChecklist();
  flushBullets();
  flushNumbered();
  return blocks;
}

/// Інлайн-токенізація `**жирний**` / `*курсив*` / `__підкреслений__` —
/// один прохід regex, без вкладеності (курсив усередині жирного тощо не
/// підтримується — свідомо, щоб парсер лишався маленьким і передбачуваним).
final RegExp _inlineToken = RegExp(r'(\*\*.+?\*\*|\*.+?\*|__.+?__)');

List<InlineSpan> buildInlineSpans(String text, TextStyle base) {
  if (text.isEmpty) return [TextSpan(text: '', style: base)];
  final spans = <InlineSpan>[];
  var last = 0;
  for (final m in _inlineToken.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start), style: base));
    }
    final token = m.group(0)!;
    if (token.startsWith('**')) {
      spans.add(TextSpan(
        text: token.substring(2, token.length - 2),
        style: base.copyWith(fontWeight: FontWeight.w800),
      ));
    } else if (token.startsWith('__')) {
      spans.add(TextSpan(
        text: token.substring(2, token.length - 2),
        style: base.copyWith(decoration: TextDecoration.underline, decorationThickness: 2),
      ));
    } else {
      spans.add(TextSpan(
        text: token.substring(1, token.length - 1),
        style: base.copyWith(fontStyle: FontStyle.italic),
      ));
    }
    last = m.end;
  }
  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last), style: base));
  }
  return spans;
}

// ── Тогл-хелпери для панелі форматування (застосовуються до поточного
// рядка курсора в TextEditingController) ────────────────────────────────

String _stripBlockPrefix(String line) {
  final bullet = _bulletLine.firstMatch(line);
  if (bullet != null) return bullet.group(1) ?? '';
  final num = _numberedLine.firstMatch(line);
  if (num != null) return num.group(1) ?? '';
  final quote = _quoteLine.firstMatch(line);
  if (quote != null) return quote.group(1) ?? '';
  final chk = _checklistLine.firstMatch(line);
  if (chk != null) return chk.group(2) ?? '';
  return line;
}

String toggleBulletLine(String line) =>
    _bulletLine.hasMatch(line) ? _stripBlockPrefix(line) : '- ${_stripBlockPrefix(line)}';

String toggleNumberedLine(String line) =>
    _numberedLine.hasMatch(line) ? _stripBlockPrefix(line) : '1. ${_stripBlockPrefix(line)}';

String toggleQuoteLine(String line) =>
    _quoteLine.hasMatch(line) ? _stripBlockPrefix(line) : '> ${_stripBlockPrefix(line)}';

String toggleChecklistLine(String line) =>
    _checklistLine.hasMatch(line) ? _stripBlockPrefix(line) : '[ ] ${_stripBlockPrefix(line)}';

/// Застосовує [lineTransform] до рядка, де зараз курсор (або до першого
/// рядка виділення, якщо виділено кілька) — і повертає новий текст +
/// позицію курсора після зміни, готові для `TextEditingController.value`.
({String text, TextSelection selection}) applyLineToggle(
  String text,
  TextSelection selection,
  String Function(String line) lineTransform,
) {
  if (!selection.isValid) return (text: text, selection: selection);
  final start = selection.start.clamp(0, text.length);
  final lineStart = start == 0 ? 0 : text.lastIndexOf('\n', start - 1) + 1;
  var lineEnd = text.indexOf('\n', start);
  if (lineEnd == -1) lineEnd = text.length;
  final line = text.substring(lineStart, lineEnd);
  final newLine = lineTransform(line);
  final newText = text.replaceRange(lineStart, lineEnd, newLine);
  final delta = newLine.length - line.length;
  final newOffset = (start + delta).clamp(lineStart, lineStart + newLine.length);
  return (text: newText, selection: TextSelection.collapsed(offset: newOffset));
}

/// Обгортає виділений текст маркером (`**`/`*`/`__`) — або вставляє
/// порожню пару маркерів на позиції курсора, якщо нічого не виділено.
({String text, TextSelection selection}) applyInlineMarker(
  String text,
  TextSelection selection,
  String marker,
) {
  if (!selection.isValid) return (text: text, selection: selection);
  if (selection.isCollapsed) {
    final at = selection.start;
    final newText = text.replaceRange(at, at, '$marker$marker');
    return (text: newText, selection: TextSelection.collapsed(offset: at + marker.length));
  }
  final selected = text.substring(selection.start, selection.end);
  final newText = text.replaceRange(selection.start, selection.end, '$marker$selected$marker');
  return (
    text: newText,
    selection: TextSelection(
      baseOffset: selection.start,
      extentOffset: selection.start + marker.length * 2 + selected.length,
    ),
  );
}

/// Перемикає стан конкретного пункту чеклиста за індексом рядка — для
/// робочого чекбокса в екрані ПЕРЕГЛЯДУ (без відкриття редагування).
String toggleChecklistByLineIndex(String raw, int lineIndex) {
  final lines = raw.split('\n');
  if (lineIndex < 0 || lineIndex >= lines.length) return raw;
  final m = _checklistLine.firstMatch(lines[lineIndex]);
  if (m == null) return raw;
  final checkedNow = m.group(1)!.toLowerCase() == 'x';
  lines[lineIndex] = '[${checkedNow ? ' ' : 'x'}] ${m.group(2) ?? ''}';
  return lines.join('\n');
}

// ── Живе підсвічування синтаксису ПІД ЧАС редагування ───────────────────
//
// buildInlineSpans/parseRichNote вище розраховані на ПЕРЕГЛЯД (rich_note_
// view.dart) — там маркери (**/*/__/[ ]/-/1./>) прибираються з відображення
// повністю. Для РЕДАГОВАНОГО TextField так робити не можна: EditableText
// мапить позицію курсора/виділення на офсети в TextSpan.text, тож сумарна
// довжина відображеного тексту МУСИТЬ точно дорівнювати controller.text —
// інакше курсор "з'їжджає" відносно того, що реально надруковано. Тому
// функції нижче ЛИШАЮТЬ усі символи-маркери на місці, лише змінюють їм
// колір (приглушують) — самі глядач бачить living-підсвітку синтаксису
// (жирне/курсив/підкреслене реально виглядає так під час набору, а не лише
// в перегляді; [ ]/-/1./> видно приглушеним кольором, а не як "просто
// текст у дужках").

List<InlineSpan> buildLiveInlineSpans(String text, TextStyle base) {
  final dim = base.copyWith(color: base.color?.withValues(alpha: 0.35));
  if (text.isEmpty) return [TextSpan(text: '', style: base)];
  final spans = <InlineSpan>[];
  var last = 0;
  for (final m in _inlineToken.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start), style: base));
    }
    final token = m.group(0)!;
    final int markerLen;
    final TextStyle innerStyle;
    if (token.startsWith('**')) {
      markerLen = 2;
      innerStyle = base.copyWith(fontWeight: FontWeight.w800);
    } else if (token.startsWith('__')) {
      markerLen = 2;
      innerStyle = base.copyWith(decoration: TextDecoration.underline, decorationThickness: 2);
    } else {
      markerLen = 1;
      innerStyle = base.copyWith(fontStyle: FontStyle.italic);
    }
    spans.add(TextSpan(text: token.substring(0, markerLen), style: dim));
    spans.add(TextSpan(text: token.substring(markerLen, token.length - markerLen), style: innerStyle));
    spans.add(TextSpan(text: token.substring(token.length - markerLen), style: dim));
    last = m.end;
  }
  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last), style: base));
  }
  return spans;
}

// Кожна з функцій нижче замінює символ(и)-маркер на ІНШИЙ символ(и) ТІЄЇ Ж
// довжини (напр. один-єдиний '-' → один-єдиний '•', 'x' → '✓') — НІКОЛИ не
// прибирає й не додає символи. Це навмисно: EditableText мапить позицію
// курсора/виділення на офсети в ЗІБРАНОМУ TextSpan.text так, ніби він і є
// controller.text — тому сумарна довжина (і навіть посимвольна довжина
// кожного шматка) мусить точно збігатися з оригінальним рядком, інакше
// курсор "з'їжджає" відносно реально надрукованого. Те, що можна безпечно
// міняти — лише САМ ГЛІФ на позиції (не її довжину) і TextStyle: той самий
// принцип, на якому побудований вбудований `TextField(obscureText: true)`
// (кожен символ пароля замінюється на "•" в ТІЙ САМІЙ позиції, без збою
// курсора) — тут той самий трюк для маркерів чекліста/списку.

List<InlineSpan> _checklistLiveSpans(String line, RegExpMatch m, TextStyle base) {
  final dim = base.copyWith(color: base.color?.withValues(alpha: 0.4));
  final checked = m.group(1)!.toLowerCase() == 'x';
  final markerChar = line[1]; // символ між '[' і ']': ' ', 'x' або 'X'
  final afterBracket = line.indexOf(']') + 1;
  final hasSpace = afterBracket < line.length && line[afterBracket] == ' ';
  final content = line.substring(hasSpace ? afterBracket + 1 : afterBracket);
  final contentStyle = checked
      ? base.copyWith(color: AppColors.textMuted, decoration: TextDecoration.lineThrough)
      : base;
  return [
    TextSpan(text: '[', style: dim),
    TextSpan(
      // 1-до-1 заміна гліфа: ' '→' ' (без змін) або 'x'/'X'→'✓' — довжина
      // лишається рівно 1 символ.
      text: checked ? '✓' : markerChar,
      style: dim.copyWith(
        color: checked ? AppColors.primary : dim.color,
        fontWeight: FontWeight.w800,
      ),
    ),
    TextSpan(text: ']', style: dim),
    if (hasSpace) TextSpan(text: ' ', style: base),
    ...buildLiveInlineSpans(content, contentStyle),
  ];
}

List<InlineSpan> _bulletLiveSpans(String line, TextStyle base) {
  final hasSpace = line.length > 1 && line[1] == ' ';
  final content = line.substring(hasSpace ? 2 : 1);
  return [
    // 1-до-1 заміна гліфа: '-' → '•', та сама позиція/довжина.
    TextSpan(text: '•', style: base.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w800)),
    if (hasSpace) TextSpan(text: ' ', style: base),
    ...buildLiveInlineSpans(content, base),
  ];
}

final RegExp _numberedLineParts = RegExp(r'^(\d+\.)(\s?)(.*)$');

List<InlineSpan> _numberedLiveSpans(String line, TextStyle base) {
  final parts = _numberedLineParts.firstMatch(line)!;
  return [
    TextSpan(
      text: parts.group(1),
      style: base.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w800),
    ),
    if (parts.group(2)!.isNotEmpty) TextSpan(text: parts.group(2), style: base),
    ...buildLiveInlineSpans(parts.group(3)!, base),
  ];
}

List<InlineSpan> _quoteLiveSpans(String line, TextStyle base) {
  final dim = base.copyWith(color: base.color?.withValues(alpha: 0.4));
  final hasSpace = line.length > 1 && line[1] == ' ';
  final content = line.substring(hasSpace ? 2 : 1);
  // background — те саме "квадратне підсвічування рядка", що й
  // AppColors.accentLight-контейнер у перегляді (rich_note_view.dart), лише
  // без лівої смужки/заокруглень (TextStyle не вміє межі) — і без зміни
  // довжини тексту.
  final quoteBg = Paint()..color = AppColors.accentLight;
  final quoteBase = base.copyWith(fontStyle: FontStyle.italic, background: quoteBg);
  return [
    TextSpan(text: '>', style: dim.copyWith(background: quoteBg)),
    if (hasSpace) TextSpan(text: ' ', style: quoteBase),
    ...buildLiveInlineSpans(content, quoteBase),
  ];
}

List<InlineSpan> buildLiveEditorSpans(String text, TextStyle base) {
  final lines = text.split('\n');
  final spans = <InlineSpan>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final chk = _checklistLine.firstMatch(line);
    if (chk != null) {
      spans.addAll(_checklistLiveSpans(line, chk, base));
    } else if (_bulletLine.hasMatch(line)) {
      spans.addAll(_bulletLiveSpans(line, base));
    } else if (_numberedLine.hasMatch(line)) {
      spans.addAll(_numberedLiveSpans(line, base));
    } else if (_quoteLine.hasMatch(line)) {
      spans.addAll(_quoteLiveSpans(line, base));
    } else {
      spans.addAll(buildLiveInlineSpans(line, base));
    }
    if (i < lines.length - 1) spans.add(TextSpan(text: '\n', style: base));
  }
  return spans;
}

/// [TextEditingController], що підсвічує синтаксис форматування прямо під
/// час набору (замість суцільного невиразного тексту з "голими" **/[ ]).
class RichNoteEditingController extends TextEditingController {
  RichNoteEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // Активне IME-компонування (напр. предиктивний ввід деяких Android-
    // клавіатур) потребує власного підкреслення composing-діапазону —
    // безпечно змішати його з нашими спанами складніше, ніж варте для
    // цього нечастого випадку, тож на час композиції лишаємо стандартну
    // поведінку.
    if (value.isComposingRangeValid && withComposing) {
      return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    }
    return TextSpan(style: style, children: buildLiveEditorSpans(text, style ?? const TextStyle()));
  }
}

/// Enter на рядку списку/чеклиста/цитати продовжує той самий маркер на
/// новому рядку (як у більшості нотаток-застосунків), замість вимоги
/// натискати кнопку панелі форматування знову для кожного пункту. Enter на
/// ПОРОЖНЬОМУ пункті списку виходить зі списку (прибирає порожній маркер),
/// а не плодить нескінченні порожні пункти.
class RichNoteListContinuationFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final cursor = newValue.selection.baseOffset;
    final insertedNewline = newValue.text.length == oldValue.text.length + 1 &&
        newValue.selection.isCollapsed &&
        cursor > 0 &&
        newValue.text[cursor - 1] == '\n';
    if (!insertedNewline) return newValue;

    final newlineOffset = cursor - 1;
    final prevLineStart =
        newlineOffset == 0 ? 0 : newValue.text.lastIndexOf('\n', newlineOffset - 1) + 1;
    final prevLine = newValue.text.substring(prevLineStart, newlineOffset);

    String? continuation;
    bool emptyItem = false;

    final chk = _checklistLine.firstMatch(prevLine);
    final bullet = _bulletLine.firstMatch(prevLine);
    final num = _numberedLine.firstMatch(prevLine);
    final quote = _quoteLine.firstMatch(prevLine);
    if (chk != null) {
      emptyItem = (chk.group(2) ?? '').trim().isEmpty;
      continuation = '[ ] ';
    } else if (bullet != null) {
      emptyItem = (bullet.group(1) ?? '').trim().isEmpty;
      continuation = '- ';
    } else if (num != null) {
      emptyItem = (num.group(1) ?? '').trim().isEmpty;
      final n = int.parse(RegExp(r'^\d+').firstMatch(prevLine)!.group(0)!);
      continuation = '${n + 1}. ';
    } else if (quote != null) {
      emptyItem = (quote.group(1) ?? '').trim().isEmpty;
      continuation = '> ';
    } else {
      return newValue;
    }

    if (emptyItem) {
      final newText = newValue.text.replaceRange(prevLineStart, newlineOffset, '');
      final removed = newlineOffset - prevLineStart;
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursor - removed),
      );
    }

    final newText = newValue.text.replaceRange(cursor, cursor, continuation);
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + continuation.length),
    );
  }
}
