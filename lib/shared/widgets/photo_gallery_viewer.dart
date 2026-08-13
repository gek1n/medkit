import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/services/peer_photo_service.dart';
import '../../core/services/photo_service.dart';
import '../../core/utils/l10n_ext.dart';
import '../../features/family/peer_view_providers.dart';

/// Повноекранний перегляд фото з масштабуванням (pinch-to-zoom) і
/// гортанням між кількома вкладеннями одного запису. PDF сюди не
/// потрапляють — для них лишається зовнішній перегляд через
/// [PhotoService.shareDecrypted], як і раніше.
///
/// [peer] — коли задано, [imagePaths] це відносні шляхи З ІНШОГО пристрою
/// (прийшли як є в синхронізованому photoPaths/documentPaths запису піра):
/// їх немає сенсу шукати локально, байти довантажуються на вимогу через
/// [PeerPhotoService] (photo_id обчислюється з того самого шляху
/// незалежно на обох пристроях).
Future<void> showPhotoGalleryViewer(
  BuildContext context, {
  required List<String> imagePaths,
  required int initialIndex,
  PeerSubject? peer,
}) {
  return Navigator.push(
    context,
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) =>
          _PhotoGalleryViewer(imagePaths: imagePaths, initialIndex: initialIndex, peer: peer),
    ),
  );
}

class _PhotoGalleryViewer extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;
  final PeerSubject? peer;
  const _PhotoGalleryViewer({required this.imagePaths, required this.initialIndex, this.peer});

  @override
  State<_PhotoGalleryViewer> createState() => _PhotoGalleryViewerState();
}

class _PhotoGalleryViewerState extends State<_PhotoGalleryViewer> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);
  late int _current = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.imagePaths.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) =>
                _ZoomableImage(path: widget.imagePaths[i], peer: widget.peer),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  if (widget.imagePaths.length > 1)
                    Text(
                      '${_current + 1} / ${widget.imagePaths.length}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  const Spacer(),
                  const SizedBox(width: 44),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomableImage extends StatelessWidget {
  final String path;
  final PeerSubject? peer;
  const _ZoomableImage({required this.path, this.peer});

  Future<Uint8List> _load() {
    final p = peer;
    return p == null
        ? PhotoService.decryptedBytes(path)
        : PeerPhotoService.fetch(channelId: p.channelId, publicKeyHex: p.publicKeyHex, relativePath: path);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 40),
                const SizedBox(height: 8),
                Text(
                  context.l10n.photoLoadError,
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        return InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Center(child: Image.memory(snapshot.data!)),
        );
      },
    );
  }
}
