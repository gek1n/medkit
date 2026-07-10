import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/avatars.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/family_peers_repository.dart';

const _entityTypeLabels = {
  'medication': 'Ліки',
  'doctor_appointment': 'Візит до лікаря',
  'lab_result': 'Аналіз',
  'allergy': 'Алергія',
  'chronic_condition': 'Хронічне захворювання',
  'vaccination': 'Щеплення',
  'surgery': 'Операція',
};

const _entityTypeIcons = {
  'medication': Icons.medication_rounded,
  'doctor_appointment': Icons.calendar_month_rounded,
  'lab_result': Icons.biotech_rounded,
  'allergy': Icons.warning_amber_rounded,
  'chronic_condition': Icons.favorite_rounded,
  'vaccination': Icons.vaccines_rounded,
  'surgery': Icons.local_hospital_rounded,
};

/// Читає найбільш "людяне" поле з довільного JSON — записи різних типів
/// мають різні назви ключового поля (name/testName/allergen/doctorType),
/// тому радше вгадуємо перше підходяще, ніж дублюємо типізовану модель
/// заради суто інформаційного, нередагованого перегляду.
String _primaryLabel(Map<String, dynamic> json) {
  for (final key in ['name', 'testName', 'allergen', 'doctorType']) {
    final v = json[key];
    if (v is String && v.isNotEmpty) return v;
  }
  return 'Запис';
}

final _sharedSubjectsProvider = StreamProvider<List<SharedSubject>>((ref) {
  return ref.watch(familyPeersRepositoryProvider).watchSharedSubjects();
});

final _sharedEntitiesProvider = StreamProvider.family<List<SharedEntity>, String>((ref, subjectPersonUuid) {
  return ref.watch(familyPeersRepositoryProvider).watchSharedEntities(subjectPersonUuid);
});

/// Read-only перегляд того, що поділився зі мною конкретний пір (Фаза 4) —
/// свідомо без редагування: дані живуть на пристрої піра, тут лише копія
/// для перегляду, синхронізована в межах наданого view-дозволу.
class SharedFamilyDataScreen extends ConsumerWidget {
  final String peerChannelId;
  final String peerName;
  const SharedFamilyDataScreen({super.key, required this.peerChannelId, required this.peerName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(_sharedSubjectsProvider);
    final subjects =
        (subjectsAsync.valueOrNull ?? const []).where((s) => s.peerChannelId == peerChannelId).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  Expanded(child: Text('Дані від $peerName', style: AppTextStyles.h3)),
                ],
              ),
            ),
            Expanded(
              child: subjectsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('$e')),
                data: (_) {
                  if (subjects.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.screenPadding),
                        child: Text(
                          '$peerName ще нічого не поділив(-ла) з вами — або доступ ще не надано.',
                          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.screenPadding,
                      AppDimensions.md,
                      AppDimensions.screenPadding,
                      AppDimensions.xl,
                    ),
                    children: [
                      for (final subject in subjects) ...[
                        Row(
                          children: [
                            AvatarImage(index: subject.avatarIndex, size: 28),
                            const SizedBox(width: 8),
                            Text(subject.name, style: AppTextStyles.labelLg),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.sm),
                        _SubjectEntities(subjectPersonUuid: subject.personUuid),
                        const SizedBox(height: AppDimensions.lg),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectEntities extends ConsumerWidget {
  final String subjectPersonUuid;
  const _SubjectEntities({required this.subjectPersonUuid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitiesAsync = ref.watch(_sharedEntitiesProvider(subjectPersonUuid));
    final entities = entitiesAsync.valueOrNull ?? const [];

    if (entities.isEmpty) {
      return Text(
        'Немає даних, доступних для перегляду',
        style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
      );
    }

    return Column(
      children: entities.map((e) {
        Map<String, dynamic> json;
        try {
          json = jsonDecode(e.dataJson) as Map<String, dynamic>;
        } catch (_) {
          json = const {};
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.sm),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(_entityTypeIcons[e.entityType] ?? Icons.description_rounded,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_primaryLabel(json), style: AppTextStyles.labelMd),
                      Text(
                        _entityTypeLabels[e.entityType] ?? e.entityType,
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
