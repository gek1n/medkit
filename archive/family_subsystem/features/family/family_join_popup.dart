import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../shared/widgets/mk_button.dart';
import '../profile/family_visibility_screen.dart';

/// М'яке поп-ап сповіщення про успішне приєднання до сім'ї — з двох боків:
/// - у ІНВАЙТЕРА (власника), коли [FamilyGroupService.refreshPeers] щойно
///   виявив, що запрошений учасник прийняв запрошення (нова [FamilyPeer]);
/// - у ІНВАЙТОВАНОГО, одразу після успішного [FamilyGroupService.acceptInvite].
/// Показується РІВНО ОДИН РАЗ на кожне успішне приєднання (дедуп —
/// [FamilyJoinPopupService]) — виклик цієї функції сам по собі не
/// перевіряє дедуп, той керується на боці викликача.
Future<void> showFamilyJoinPopup(
  BuildContext context, {
  required String peerName,
  required bool asInvitee,
  required int ownMemberId,
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
                MaterialPageRoute(
                  builder: (_) => FamilyVisibilityScreen(subjectMemberId: ownMemberId),
                ),
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
