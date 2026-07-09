import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/ai_consent_service.dart';
import '../../core/services/prescription_scan_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/mk_screen_header.dart';

const _consentKind = 'scan';

enum _ScanState { checkingConsent, needsConsent, pickingPhotos, scanning, results, error }

class _MedDraft {
  bool included = true;
  late TextEditingController nameController;
  late TextEditingController doseController;
  final String? doseUnit;
  final List<String>? scheduleTimes;
  final String? foodRelation;
  final List<String>? sideEffects;

  _MedDraft(ScannedMedication m)
      : doseUnit = m.doseUnit,
        scheduleTimes = m.scheduleTimes,
        foodRelation = m.foodRelation,
        sideEffects = m.sideEffects {
    nameController = TextEditingController(text: m.name);
    doseController = TextEditingController(text: m.doseAmount?.toString() ?? '');
  }

  void dispose() {
    nameController.dispose();
    doseController.dispose();
  }

  ScannedMedication toScannedMedication() => ScannedMedication(
        name: nameController.text.trim(),
        doseAmount: double.tryParse(doseController.text.replaceAll(',', '.')),
        doseUnit: doseUnit,
        scheduleTimes: scheduleTimes,
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
        _drafts = results.map((m) => _MedDraft(m)).toList();
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
          child: Text(
            '⚠️ Дозування, розклад і довідкова інформація про побічні ефекти — '
            'орієнтовні. Завжди звіряйте з інструкцією до препарату.',
            style: AppTextStyles.bodySm.copyWith(color: const Color(0xFF92400E)),
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
  static const _foodLabels = {'before': 'До їжі', 'after': 'Після їжі', 'any': 'Незалежно від їжі'};
  static const _scheduleLabels = {
    'morning': 'Вранці',
    'afternoon': 'Вдень',
    'evening': 'Ввечері',
    'night': 'Вночі',
  };

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
              const SizedBox(height: AppDimensions.md),
              ...widget.drafts.map(_buildDraftCard),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
              ),
              child: Text('Додати обрані',
                  style: AppTextStyles.bodyMd
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDraftCard(_MedDraft d) {
    return StatefulBuilder(
      builder: (context, setCardState) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 16,
                offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: d.included,
                  onChanged: (v) => setCardState(() => d.included = v ?? true),
                  activeColor: AppColors.primary,
                ),
                Expanded(
                  child: TextField(
                    controller: d.nameController,
                    style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: d.doseController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Доза',
                            suffixText: d.doseUnit,
                          ),
                        ),
                      ),
                      if (d.scheduleTimes != null && d.scheduleTimes!.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            d.scheduleTimes!.map((s) => _scheduleLabels[s] ?? s).join(' + '),
                            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (d.foodRelation != null || (d.sideEffects?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (d.foodRelation != null)
                            Text('🍽 ${_foodLabels[d.foodRelation] ?? d.foodRelation}',
                                style: AppTextStyles.bodySm.copyWith(color: const Color(0xFF92400E))),
                          if (d.sideEffects?.isNotEmpty ?? false)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('⚡ Можливі побічні ефекти: ${d.sideEffects!.join(', ')}',
                                  style: AppTextStyles.bodySm.copyWith(color: const Color(0xFF92400E))),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            '⚠️ Довідково, не гарантовано. Звірте з інструкцією до препарату.',
                            style: AppTextStyles.caption.copyWith(color: const Color(0xFF92400E)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
