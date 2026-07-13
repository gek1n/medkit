import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/ai_consent_service.dart';
import '../../core/services/camera_permission_service.dart';
import '../../core/services/prescription_scan_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/form_chips.dart';
import '../../shared/widgets/mk_screen_header.dart';

const _consentKind = 'scan';

enum _ScanState { checkingConsent, needsConsent, pickingPhotos, scanning, results, error }

/// Чернетка одного розпізнаного препарату на екрані перегляду результатів
/// сканування. [included] — це і є явна згода користувача додати саме цей
/// препарат: за замовчуванням false (те, що розпізнав ІІ, ще не підтверджено),
/// стає true лише коли користувач сам відмітив чекбокс.
class _MedDraft {
  bool included = false;
  bool expanded;
  late TextEditingController nameController;
  late TextEditingController doseController;
  String form;
  List<String> scheduleTimes;
  String foodRelation;
  int durationDays;
  final List<String>? sideEffects;

  _MedDraft(ScannedMedication m, {required bool expandByDefault})
      : form = m.form ?? 'tablet',
        scheduleTimes = List.of(m.scheduleTimes ?? const ['morning']),
        foodRelation = m.foodRelation ?? 'any',
        durationDays = m.durationDays ?? 7,
        sideEffects = m.sideEffects,
        expanded = expandByDefault {
    nameController = TextEditingController(text: m.name);
    doseController = TextEditingController(text: m.doseAmount?.toString() ?? '');
  }

  void dispose() {
    nameController.dispose();
    doseController.dispose();
  }

  ScannedMedication toScannedMedication() => ScannedMedication(
        name: nameController.text.trim(),
        form: form,
        doseAmount: double.tryParse(doseController.text.replaceAll(',', '.')),
        doseUnit: unitForMedForm(form),
        scheduleTimes: scheduleTimes,
        durationDays: durationDays,
        foodRelation: foodRelation,
        sideEffects: sideEffects,
      );
}

/// Сканування фото рецепта чи упаковок ліків (одне чи кілька за раз).
/// Розпізнавання і довідкова інформація (їжа/побічні ефекти) — через Claude
/// на бекенді (`/scan/prescription`). Повертає обрані користувачем
/// [ScannedMedication] через `Navigator.pop` — сам екран нічого не зберігає
/// в БД, це відповідальність того, хто його відкрив (форма додавання ліків
/// чи онбординг).
class PrescriptionScanScreen extends StatefulWidget {
  const PrescriptionScanScreen({super.key});

  @override
  State<PrescriptionScanScreen> createState() => _PrescriptionScanScreenState();
}

class _PrescriptionScanScreenState extends State<PrescriptionScanScreen> {
  final _scanService = PrescriptionScanService();
  final _picker = ImagePicker();

  _ScanState _state = _ScanState.checkingConsent;
  final List<File> _pickedImages = [];
  List<_MedDraft> _drafts = [];
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _checkConsent();
  }

  @override
  void dispose() {
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  Future<void> _checkConsent() async {
    final given = await AiConsentService.hasConsent(_consentKind);
    if (!mounted) return;
    setState(() => _state = given ? _ScanState.pickingPhotos : _ScanState.needsConsent);
  }

  Future<void> _onConsentGiven() async {
    await AiConsentService.recordConsent(_consentKind);
    if (!mounted) return;
    setState(() => _state = _ScanState.pickingPhotos);
  }

  Future<void> _addFromCamera() async {
    final granted = await CameraPermissionService.ensureGranted();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Немає доступу до камери. Дозвольте його в налаштуваннях телефону.')),
        );
      }
      return;
    }
    final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (photo != null) setState(() => _pickedImages.add(File(photo.path)));
  }

  Future<void> _addFromGallery() async {
    final photos = await _picker.pickMultiImage(imageQuality: 85);
    if (photos.isNotEmpty) {
      setState(() => _pickedImages.addAll(photos.map((p) => File(p.path))));
    }
  }

  Future<void> _runScan() async {
    setState(() => _state = _ScanState.scanning);
    try {
      final results = await _scanService.scan(_pickedImages);
      if (!mounted) return;
      if (results.isEmpty) {
        setState(() {
          _errorMsg = 'Не вдалося розпізнати ліки на фото. Спробуйте зробити чіткіше фото.';
          _state = _ScanState.error;
        });
        return;
      }
      setState(() {
        _drafts = results
            .asMap()
            .entries
            .map((e) => _MedDraft(e.value, expandByDefault: e.key == 0))
            .toList();
        _state = _ScanState.results;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Помилка сканування: $e';
        _state = _ScanState.error;
      });
    }
  }

  void _confirm() {
    final selected = _drafts
        .where((d) => d.included && d.nameController.text.trim().isNotEmpty)
        .map((d) => d.toScannedMedication())
        .toList();
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const MkScreenHeader(title: 'Сканувати рецепт'),
            Expanded(
              child: switch (_state) {
                _ScanState.checkingConsent || _ScanState.scanning =>
                  const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary)),
                _ScanState.needsConsent =>
                  _ConsentBody(onAgree: _onConsentGiven),
                _ScanState.pickingPhotos => _PickingBody(
                    images: _pickedImages,
                    onCamera: _addFromCamera,
                    onGallery: _addFromGallery,
                    onRemove: (i) =>
                        setState(() => _pickedImages.removeAt(i)),
                    onScan: _pickedImages.isEmpty ? null : _runScan,
                  ),
                _ScanState.results =>
                  _ResultsBody(drafts: _drafts, onConfirm: _confirm),
                _ScanState.error => _ErrorBody(
                    message: _errorMsg,
                    onRetry: () =>
                        setState(() => _state = _ScanState.pickingPhotos),
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────── consent body ──────────────────────────────

class _ConsentBody extends StatelessWidget {
  final VoidCallback onAgree;
  const _ConsentBody({required this.onAgree});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      children: [
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryLighter, width: 2.5),
            ),
            child: const Center(
              child: Icon(Icons.camera_alt_outlined, size: 44, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Перш ніж почати',
            textAlign: TextAlign.center, style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: AppColors.primaryLighter),
          ),
          child: Text(
            'Щоб розпізнати ліки, фото рецепта чи упаковки надсилається сервісу '
            'Anthropic (Claude). Фото використовується лише для розпізнавання і '
            'ніде не зберігається після відповіді.',
            style: AppTextStyles.bodyMd,
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.warningLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Text.rich(
            TextSpan(
              style: AppTextStyles.bodySm.copyWith(color: const Color(0xFF92400E)),
              children: [
                const TextSpan(text: '⚠️ Дозування, розклад і довідкова інформація про побічні ефекти — орієнтовні. '),
                TextSpan(
                  text: 'Завжди звіряйте з інструкцією до препарату.',
                  style: AppTextStyles.bodySm.copyWith(
                    color: const Color(0xFF92400E),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.xl),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onAgree,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
            ),
            child: Text('Зрозуміло, погоджуюсь',
                style: AppTextStyles.bodyMd
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────── picking body ──────────────────────────────

class _PickingBody extends StatelessWidget {
  final List<File> images;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final ValueChanged<int> onRemove;
  final VoidCallback? onScan;

  const _PickingBody({
    required this.images,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      children: [
        Text(
          'Сфотографуйте рецепт або упаковку. Можна додати кілька фото, якщо '
          'ліків декілька.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
        ),
        const SizedBox(height: AppDimensions.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Камера'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Галерея'),
              ),
            ),
          ],
        ),
        if (images.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.lg),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: images.asMap().entries.map((e) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(e.value, width: 90, height: 90, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () => onRemove(e.key),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: AppDimensions.xl),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onScan,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.border,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
            ),
            child: Text('Сканувати${images.isNotEmpty ? ' (${images.length})' : ''}',
                style: AppTextStyles.bodyMd
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────── results body ──────────────────────────────

class _ResultsBody extends StatefulWidget {
  final List<_MedDraft> drafts;
  final VoidCallback onConfirm;
  const _ResultsBody({required this.drafts, required this.onConfirm});

  @override
  State<_ResultsBody> createState() => _ResultsBodyState();
}

class _ResultsBodyState extends State<_ResultsBody> {
  int get _selectedCount => widget.drafts.where((d) => d.included).length;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            children: [
              Text('Розпізнано ${widget.drafts.length}. Перевірте перед додаванням:',
                  style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                'Розгорніть препарат, перевірте дані і поставте галочку, щоб підтвердити додавання.',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
              ),
              const SizedBox(height: AppDimensions.md),
              ...widget.drafts.map(
                (d) => _DraftCard(draft: d, onChanged: () => setState(() {})),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedCount == 0 ? null : widget.onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
              ),
              child: Text(
                _selectedCount == 0 ? 'Оберіть препарати' : 'Додати обрані ($_selectedCount)',
                style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────── draft card (accordion) ─────────────────────

class _DraftCard extends StatefulWidget {
  final _MedDraft draft;
  final VoidCallback onChanged;
  const _DraftCard({required this.draft, required this.onChanged});

  @override
  State<_DraftCard> createState() => _DraftCardState();
}

class _DraftCardState extends State<_DraftCard> {
  static const _foodLabels = {'before': 'До їжі', 'after': 'Після їжі', 'any': 'Незалежно від їжі'};
  static const _scheduleLabels = {
    'morning': 'Вранці',
    'afternoon': 'Вдень',
    'evening': 'Ввечері',
    'night': 'Вночі',
  };

  _MedDraft get d => widget.draft;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: d.included ? AppColors.primary : AppColors.border,
          width: d.included ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            onTap: () => setState(() => d.expanded = !d.expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.nameController.text.trim().isEmpty
                              ? 'Без назви'
                              : d.nameController.text.trim(),
                          style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            medFormLabels[d.form] ?? d.form,
                            if (d.doseController.text.trim().isNotEmpty)
                              '${d.doseController.text.trim()} ${unitForMedForm(d.form)}',
                          ].join(' · '),
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() => d.included = !d.included);
                      widget.onChanged();
                    },
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: d.included ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: d.included ? AppColors.primary : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: d.included
                          ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    d.expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (d.expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 8),
                  Text('НАЗВА', style: AppTextStyles.labelSm),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: d.nameController,
                      onChanged: (_) => setState(() {}),
                      style: AppTextStyles.bodyMd,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text('ФОРМА ВИПУСКУ', style: AppTextStyles.labelSm),
                  const SizedBox(height: 8),
                  FormChips(selected: d.form, onSelect: (f) => setState(() => d.form = f)),
                  const SizedBox(height: 14),

                  Text('ДОЗА', style: AppTextStyles.labelSm),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 130,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: d.doseController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: AppTextStyles.bodyMd,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: InputBorder.none,
                          suffixText: unitForMedForm(d.form),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text('ЧАС ПРИЙОМУ', style: AppTextStyles.labelSm),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _scheduleLabels.entries.map((e) {
                      final sel = d.scheduleTimes.contains(e.key);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (sel) {
                            d.scheduleTimes.remove(e.key);
                          } else {
                            d.scheduleTimes.add(e.key);
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: sel ? AppColors.primary : AppColors.border),
                          ),
                          child: Text(
                            e.value,
                            style: AppTextStyles.labelMd.copyWith(
                              color: sel ? Colors.white : AppColors.textMain,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  Text('ТРИВАЛІСТЬ КУРСУ', style: AppTextStyles.labelSm),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StepperButton(
                        icon: Icons.remove_rounded,
                        onTap: d.durationDays > 1 ? () => setState(() => d.durationDays--) : null,
                      ),
                      SizedBox(
                        width: 64,
                        child: Text(
                          '${d.durationDays} дн.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      _StepperButton(
                        icon: Icons.add_rounded,
                        onTap: () => setState(() => d.durationDays++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Text('ЗВ\'ЯЗОК З ЇЖЕЮ', style: AppTextStyles.labelSm),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _foodLabels.entries.map((e) {
                      final sel = d.foodRelation == e.key;
                      return GestureDetector(
                        onTap: () => setState(() => d.foodRelation = e.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: sel ? AppColors.primary : AppColors.border),
                          ),
                          child: Text(
                            e.value,
                            style: AppTextStyles.labelMd.copyWith(
                              color: sel ? Colors.white : AppColors.textMain,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  if (d.sideEffects?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Text.rich(
                        TextSpan(
                          style: AppTextStyles.bodySm.copyWith(color: const Color(0xFF92400E)),
                          children: [
                            TextSpan(text: '⚡ Можливі побічні ефекти: ${d.sideEffects!.join(', ')}. '),
                            const TextSpan(
                              text: 'Звірте з інструкцією до препарату.',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => d.included = true);
                        widget.onChanged();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        ),
                      ),
                      child: Text(
                        d.included ? 'Підтверджено ✓' : 'Все вірно, підтвердити',
                        style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.bg : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 16, color: onTap == null ? AppColors.textMuted : AppColors.primary),
      ),
    );
  }
}

// ────────────────────────────── error body ──────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sentiment_dissatisfied_rounded,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('Щось пішло не так', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
            ),
            child: const Text('Спробувати ще раз'),
          ),
        ],
      ),
    );
  }
}
