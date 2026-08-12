import 'package:flutter/material.dart';

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
