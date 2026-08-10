import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/providers/database_provider.dart';
import '../../core/services/family_group_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/db/app_database.dart';
import '../../shared/widgets/mk_screen_header.dart';

/// Запрошення до сімейної групи — рівноправний учасник зі своєю карткою
/// (ім'я/аватар), без автоматичної передачі медичних даних. Видимість між
/// учасниками налаштовується окремо, вже після приєднання.
///
/// Якщо передано [forDependent] — це не звичайне запрошення нового учасника,
/// а перетворення вже наявного ЛОКАЛЬНОГО профілю на незалежний
/// ("Локальний → Автономний"): той, хто відсканує код, отримає на своєму
/// пристрої повну історію [forDependent] як стартові дані власного акаунта
/// (див. `FamilyGroupService.createConversionInvite`).
class FamilyGroupInviteScreen extends ConsumerStatefulWidget {
  final Member? forDependent;
  const FamilyGroupInviteScreen({super.key, this.forDependent});

  @override
  ConsumerState<FamilyGroupInviteScreen> createState() => _FamilyGroupInviteScreenState();
}

class _FamilyGroupInviteScreenState extends ConsumerState<FamilyGroupInviteScreen> {
  String? _code;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final db = ref.read(databaseProvider);
      final dependent = widget.forDependent;
      final code = dependent != null
          ? await FamilyGroupService(db).createConversionInvite(dependent)
          : await FamilyGroupService(db).createInvite();
      if (!mounted) return;
      setState(() {
        _code = code;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            MkScreenHeader(
                title: widget.forDependent != null
                    ? context.l10n.inviteMemberTitle(widget.forDependent!.name)
                    : context.l10n.inviteToFamilyTitle),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildError(context)
                        : _buildCode(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
          const SizedBox(height: 16),
          Text(context.l10n.inviteCreateErrorTitle, style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _generate, child: Text(context.l10n.tryAgainAction)),
        ],
      ),
    );
  }

  Widget _buildCode(BuildContext context) {
    final code = _code!;
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Image.asset('assets/illustrations/family.png', height: 140),
          const SizedBox(height: 16),
          Text(
            widget.forDependent != null
                ? context.l10n.inviteDependentBody(widget.forDependent!.name)
                : context.l10n.inviteMemberBody,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 6)),
              ],
            ),
            child: QrImageView(
              data: code,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: AppColors.surface,
              eyeStyle: const QrEyeStyle(color: AppColors.primary),
              dataModuleStyle: const QrDataModuleStyle(color: AppColors.textMain),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n.inviteScanOrEnterHint,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.codeCopiedSnackbar)),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryLighter, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    code,
                    style: AppTextStyles.h2.copyWith(color: AppColors.primary, letterSpacing: 4),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A), width: 1),
            ),
            child: Row(
              children: [
                const Text('ℹ️', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.inviteCodeExpiryNotice,
                    style: AppTextStyles.bodySm.copyWith(color: const Color(0xFF92400E)),
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
