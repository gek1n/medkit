import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/services/photo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import 'photo_gallery_viewer.dart';

/// Список вкладень (фото + PDF) з можливістю додавати/видаляти/переглядати
/// декілька документів — заміна одиночного `PhotoAttachmentBox` там, де
/// потрібно кілька файлів на запис (аналізи, візити, майбутні операції).
class DocumentsSection extends StatefulWidget {
  final List<String> paths;
  final void Function(List<String>) onChanged;
  /// За замовчуванням — локалізований [AppLocalizations.documentsLabel].
  final String? label;
  /// Лише перегляд (тап відкриває файл) — без "Додати" й без хрестика
  /// видалення на мініатюрах. Для екранів перегляду запису медкартки.
  final bool readOnly;

  const DocumentsSection({
    super.key,
    required this.paths,
    required this.onChanged,
    this.label,
    this.readOnly = false,
  });

  @override
  State<DocumentsSection> createState() => _DocumentsSectionState();
}

class _DocumentsSectionState extends State<DocumentsSection> {
  final Map<String, Uint8List> _bytesCache = {};
  bool _busy = false;

  Future<Uint8List> _decrypted(String rel) async {
    return _bytesCache[rel] ??= await PhotoService.decryptedBytes(rel);
  }

  Future<void> _add() async {
    setState(() => _busy = true);
    try {
      final path = await PhotoService.showPickerDialog(context);
      if (path != null) {
        widget.onChanged([...widget.paths, path]);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(String rel) async {
    await PhotoService.delete(rel);
    _bytesCache.remove(rel);
    widget.onChanged(widget.paths.where((p) => p != rel).toList());
  }

  Future<void> _open(String rel) async {
    if (PhotoService.isPdf(rel)) {
      await PhotoService.shareDecrypted(rel);
      return;
    }
    // Фото — перегляд і масштабування прямо в застосунку, з гортанням між
    // усіма фото цього ж запису (PDF пропускаємо, для них лишається шеринг).
    final images = widget.paths.where((p) => !PhotoService.isPdf(p)).toList();
    if (!mounted) return;
    await showPhotoGalleryViewer(
      context,
      imagePaths: images,
      initialIndex: images.indexOf(rel).clamp(0, images.length - 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.label ?? l10n.documentsLabel, style: AppTextStyles.labelMd),
            const Spacer(),
            if (!widget.readOnly)
              if (_busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                GestureDetector(
                  onTap: _add,
                  child: Text(l10n.addAction,
                      style: AppTextStyles.labelSm.copyWith(color: AppColors.primary)),
                ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.paths.isEmpty)
          widget.readOnly
              ? Text(l10n.noDocumentsLabel,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted))
              : GestureDetector(
                  onTap: _busy ? null : _add,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.attach_file_rounded, color: AppColors.primary),
                        const SizedBox(height: 6),
                        Text(l10n.addPhotoOrPdfLabel,
                            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub)),
                      ],
                    ),
                  ),
                )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.paths
                .map((rel) => _DocumentTile(
                      path: rel,
                      isPdf: PhotoService.isPdf(rel),
                      loadBytes: () => _decrypted(rel),
                      onTap: () => _open(rel),
                      onRemove: widget.readOnly ? null : () => _remove(rel),
                    ))
                .toList(),
          ),
        if (!widget.readOnly) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(l10n.documentsPrivacyHint,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final String path;
  final bool isPdf;
  final Future<Uint8List> Function() loadBytes;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _DocumentTile({
    required this.path,
    required this.isPdf,
    required this.loadBytes,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          onTap: onTap,
          child: Container(
            width: 88,
            height: 88,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: isPdf
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded,
                          size: 28, color: AppColors.danger),
                      const SizedBox(height: 4),
                      Text(context.l10n.pdfLabel,
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub)),
                    ],
                  )
                : FutureBuilder<Uint8List>(
                    future: loadBytes(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                    },
                  ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
