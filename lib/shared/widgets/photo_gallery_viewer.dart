import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/services/photo_service.dart';

/// Повноекранний перегляд фото з масштабуванням (pinch-to-zoom) і
/// гортанням між кількома вкладеннями одного запису. PDF сюди не
/// потрапляють — для них лишається зовнішній перегляд через
/// [PhotoService.shareDecrypted], як і раніше.
Future<void> showPhotoGalleryViewer(
  BuildContext context, {
  required List<String> imagePaths,
  required int initialIndex,
}) {
  return Navigator.push(
    context,
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) =>
          _PhotoGalleryViewer(imagePaths: imagePaths, initialIndex: initialIndex),
    ),
  );
}

class _PhotoGalleryViewer extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;
  const _PhotoGalleryViewer({required this.imagePaths, required this.initialIndex});

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
            itemBuilder: (context, i) => _ZoomableImage(path: widget.imagePaths[i]),
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
  const _ZoomableImage({required this.path});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: PhotoService.decryptedBytes(path),
      builder: (context, snapshot) {
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
