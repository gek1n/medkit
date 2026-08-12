import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/avatars.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/db/creator_info.dart';
import '../../features/family/peer_view_providers.dart';
import '../../features/today/providers/today_providers.dart' show allMembersProvider;

/// Підпис "Створив(ла): Ім'я" внизу екрана перегляду запису — Ліки/
/// Нагадування/Рутини/нотатки Поличок. Два джерела даних:
/// - [localId] (без [peer]) — локальний запис, читається з record_creators
///   (raw SQL, lib/data/db/creator_info.dart) за (entityType, localId).
/// - [peer]+[entityUuid] — перегляд запису піра через переклад кешу;
///   creator-поля прийшли самим payload'ом синку (family_server_sync_service
///   дописує їх у json вручну, бо вони не фізичні колонки), читаємо через
///   [peerCreatorsProvider].
class CreatedByFooter extends ConsumerWidget {
  final String entityType;
  final int? localId;
  final PeerSubject? peer;
  final String? entityUuid;

  const CreatedByFooter({
    super.key,
    required this.entityType,
    this.localId,
    this.peer,
  }) : entityUuid = null;

  const CreatedByFooter.forPeer({
    super.key,
    required this.entityType,
    required this.peer,
    required this.entityUuid,
  }) : localId = null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (peer != null) {
      final uuid = entityUuid;
      if (uuid == null) return const SizedBox.shrink();
      final creators = ref.watch(peerCreatorsProvider((peer!.personUuid, entityType)));
      final info = creators[uuid];
      if (info == null) return const SizedBox.shrink();
      return _CreatedByLabel(
        personUuid: info.personUuid,
        name: info.name,
        avatarIndex: info.avatarIndex,
      );
    }

    final id = localId;
    if (id == null) return const SizedBox.shrink();
    final db = ref.watch(databaseProvider);

    return FutureBuilder<CreatorInfo?>(
      future: lookupCreator(db, entityType, id),
      builder: (context, snap) {
        final info = snap.data;
        if (info == null) return const SizedBox.shrink();
        return _CreatedByLabel(
          personUuid: info.personUuid,
          name: info.name,
          avatarIndex: info.avatarIndex,
        );
      },
    );
  }
}

class _CreatedByLabel extends ConsumerWidget {
  final String? personUuid;
  final String name;
  final int avatarIndex;

  const _CreatedByLabel({
    required this.personUuid,
    required this.name,
    required this.avatarIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uuid = personUuid;
    if (uuid == null) return const SizedBox.shrink();

    final ownUuid = ref.watch(ownPersonUuidProvider);
    final isSelf = ownUuid != null && uuid == ownUuid;

    String liveName = name;
    int liveAvatar = avatarIndex;
    if (isSelf) {
      final owner = ref.watch(allMembersProvider).valueOrNull?.where((m) => m.role == 'owner').firstOrNull;
      if (owner != null) {
        liveName = owner.name;
        liveAvatar = owner.avatarIndex;
      }
    } else {
      final peerEntry = ref.watch(allFamilyPeersProvider).where((p) => p.personUuid == uuid).firstOrNull;
      if (peerEntry != null) {
        liveName = peerEntry.name;
        liveAvatar = peerEntry.avatarIndex;
      }
    }
    if (liveName.isEmpty) return const SizedBox.shrink();

    final label = context.l10n.createdByLabel(liveName) + (isSelf ? context.l10n.createdBySelfSuffix : '');

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AvatarImage(index: liveAvatar, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
