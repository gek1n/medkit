import 'package:flutter/material.dart';
import '../../core/utils/l10n_ext.dart';
import '../../shared/widgets/legal_webview_screen.dart';

/// Умови використання — див. [LegalWebViewScreen]: показує живу сторінку
/// сайту замість окремої копії тексту в застосунку.
class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalWebViewScreen(
      title: context.l10n.termsOfUseLinkLabel,
      url: 'https://elly-medkit.com/terms.html',
    );
  }
}
