import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../../core/services/family_peer_sync_service.dart';
import '../../core/services/peer_photo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';

/// Стан вкладення піра: ще не запитане → "Запросити файл"; запит
/// надіслано, але файл не прийшов → "Очікуємо файл…"; файл уже локально
/// → тап відкриває перегляд. Дані самого файлу приходять лише за запитом
/// (GDPR-мінімізація), а не пушаться заздалегідь разом з текстовими
/// полями запису.
///
/// Крок 4.2 плану: спочатку жила лише в shared_family_data_screen.dart
/// (окремий флет-переглядач чужих даних); Крок 4.3.5 виніс її сюди, щоб
/// той самий вже робочий механізм підвантаження фото за запитом можна
/// було переюзати і в реальних екранах перегляду запису (ліки/рутина/
/// нагадування/Полички), коли переглядається запис автономного піра.
class PeerAttachmentChip extends ConsumerStatefulWidget {
  final String channelId;
  final String photoPath;
  const PeerAttachmentChip({super.key, required this.channelId, required this.photoPath});

  @override
  ConsumerState<PeerAttachmentChip> createState() => _PeerAttachmentChipState();
}

enum _AttachmentState { unknown, available, pending, none }

class _PeerAttachmentChipState extends ConsumerState<PeerAttachmentChip> {
  _AttachmentState _state = _AttachmentState.unknown;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final exists = await PeerPhotoService.exists(widget.channelId, widget.photoPath);
    if (exists) {
      if (mounted) setState(() => _state = _AttachmentState.available);
      return;
    }
    final pending = await PeerPhotoService.isRequested(widget.channelId, widget.photoPath);
    if (mounted) {
      setState(() => _state = pending ? _AttachmentState.pending : _AttachmentState.none);
    }
  }

  Future<void> _request() async {
    setState(() => _state = _AttachmentState.pending);
    try {
      await FamilyPeerSyncService(ref.read(databaseProvider))
          .requestPhoto(channelId: widget.channelId, photoPath: widget.photoPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.fileRequestSentSnackbar)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _state = _AttachmentState.none);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.fileRequestFailedError('$e'))),
        );
      }
    }
  }

  Future<void> _open() async {
    try {
      final bytes = await PeerPhotoService.decryptedBytes(widget.channelId, widget.photoPath);
      if (!mounted) return;
      if (PeerPhotoService.isPdf(widget.photoPath)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.pdfReceivedSavedSnackbar)),
        );
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(12),
          child: InteractiveViewer(child: Image.memory(bytes)),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.fileOpenFailedError('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPdf = PeerPhotoService.isPdf(widget.photoPath);
    final baseIcon = isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded;

    late final IconData icon;
    late final String label;
    late final VoidCallback? onTap;
    late final Color color;

    switch (_state) {
      case _AttachmentState.unknown:
        icon = baseIcon;
        label = context.l10n.loadingEllipsis;
        onTap = null;
        color = AppColors.textMuted;
      case _AttachmentState.available:
        icon = baseIcon;
        label = isPdf ? context.l10n.pdfLabel : context.l10n.photoLabel;
        onTap = _open;
        color = AppColors.primary;
      case _AttachmentState.pending:
        icon = Icons.hourglass_top_rounded;
        label = context.l10n.awaitingFileLabel;
        onTap = null;
        color = AppColors.textMuted;
      case _AttachmentState.none:
        icon = Icons.download_rounded;
        label = context.l10n.requestFileAction;
        onTap = _request;
        color = AppColors.primary;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(label, style: AppTextStyles.bodySm.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
