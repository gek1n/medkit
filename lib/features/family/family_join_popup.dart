import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../shared/widgets/mk_button.dart';
import '../profile/family_visibility_screen.dart';

/// М'яке поп-ап сповіщення про успішне приєднання до сім'ї — з двох боків:
/// - у ІНШИХ активних учасників, коли вони помітили (на наступному
///   `/family/status`), що з'явився новий учасник — окремий показ на
///   кожного нового (дедуп — [FamilyJoinPopupService.shouldShowForOwner]);
/// - у щойно приєднаного, одразу після успішного [FamilyGroupService.
///   acceptInvite] — один показ на сім'ю (дедуп — [shouldShowForInvitee]).
/// Показується РІВНО ОДИН РАЗ на кожне успішне приєднання — виклик цієї
/// функції сам по собі не перевіряє дедуп, той керується на боці викликача.
Future<void> showFamilyJoinPopup(
  BuildContext context, {
  required String peerName,
  required bool asInvitee,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/illustrations/elly22.png', height: 120),
          const SizedBox(height: AppDimensions.md),
          Text(
            asInvitee
                ? ctx.l10n.familyJoinPopupInviteeBody(peerName)
                : ctx.l10n.familyJoinPopupOwnerBody(peerName),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: AppDimensions.lg),
          MkButton(
            label: ctx.l10n.yesAction,
            isFullWidth: true,
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(
                ctx,
                MaterialPageRoute(builder: (_) => const FamilyVisibilityScreen()),
              );
            },
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l10n.laterAction)),
        ],
      ),
    ),
  );
}
