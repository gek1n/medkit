import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/services/photo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import 'photo_gallery_viewer.dart';

/// Картка-"пост" у стилі Instagram-стрічки — спільний вигляд для всіх
/// стрічок записів у Архіві (довільні розділи, Архів нагадувань тощо).
/// Коли є фото — воно велике зверху (тап відкриває повноекранний перегляд
/// з масштабуванням); без фото картка просто компактніша.
class FeedPostCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String dateLabel;
  final String? subtitle;
  final String? notePreview;
  final List<String> tags;
  final List<String> photoPaths;
  final VoidCallback onTap;

  const FeedPostCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.dateLabel,
    this.subtitle,
    this.notePreview,
    this.tags = const [],
    this.photoPaths = const [],
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPaths.isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasPhoto)
              GestureDetector(
                onTap: () => showPhotoGalleryViewer(context, imagePaths: photoPaths, initialIndex: 0),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: FutureBuilder<Uint8List>(
                        future: PhotoService.decryptedBytes(photoPaths.first),
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return Container(color: color.withValues(alpha: 0.08));
                          }
                          return Image.memory(snap.data!, fit: BoxFit.cover, width: double.infinity);
                        },
                      ),
                    ),
                    if (photoPaths.length > 1)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_library_rounded, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text('${photoPaths.length}',
                                  style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!hasPhoto)
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: AppDimensions.md),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      child: Icon(icon, size: 20, color: color),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyles.labelLg, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                          subtitle != null ? '$dateLabel · $subtitle' : dateLabel,
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (notePreview != null && notePreview!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            notePreview!,
                            style: AppTextStyles.bodySm,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (tags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: tags
                                .map((t) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                                      ),
                                      child: Text(
                                        t,
                                        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
