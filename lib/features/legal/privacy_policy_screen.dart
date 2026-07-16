import 'package:flutter/material.dart';
import '../../core/utils/l10n_ext.dart';
import '../../shared/widgets/legal_webview_screen.dart';

/// Політика конфіденційності — див. [LegalWebViewScreen]: показує живу
/// сторінку сайту замість окремої копії тексту в застосунку.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalWebViewScreen(
      title: context.l10n.privacyPolicyLabel,
      url: 'https://elly-medkit.com/privacy.html',
    );
  }
}
