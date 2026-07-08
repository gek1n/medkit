/// Витягує id відео з поширених форматів посилань YouTube
/// (watch?v=, youtu.be/, shorts/, embed/) — потрібен лише для прев'ю-картинки
/// (`https://img.youtube.com/vi/<id>/hqdefault.jpg`), сам плеєр не вбудовуємо.
String? youtubeVideoId(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;
  final patterns = [
    RegExp(r'(?:v=|\/embed\/|\/shorts\/|\/v\/)([a-zA-Z0-9_-]{11})'),
    RegExp(r'youtu\.be\/([a-zA-Z0-9_-]{11})'),
  ];
  for (final p in patterns) {
    final match = p.firstMatch(trimmed);
    if (match != null) return match.group(1);
  }
  return null;
}

String? youtubeThumbnailUrl(String? url) {
  if (url == null) return null;
  final id = youtubeVideoId(url);
  if (id == null) return null;
  return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
}
