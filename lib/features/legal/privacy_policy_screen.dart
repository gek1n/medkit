import '../../shared/widgets/legal_webview_screen.dart';

/// Політика конфіденційності — див. [LegalWebViewScreen]: показує живу
/// сторінку сайту замість окремої копії тексту в застосунку.
class PrivacyPolicyScreen extends LegalWebViewScreen {
  const PrivacyPolicyScreen({super.key})
      : super(
          title: 'Політика конфіденційності',
          url: 'https://elly-medkit.com/privacy.html',
        );
}
