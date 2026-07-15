import '../../shared/widgets/legal_webview_screen.dart';

/// Умови використання — див. [LegalWebViewScreen]: показує живу сторінку
/// сайту замість окремої копії тексту в застосунку.
class TermsOfUseScreen extends LegalWebViewScreen {
  const TermsOfUseScreen({super.key})
      : super(
          title: 'Умови використання',
          url: 'https://elly-medkit.com/terms.html',
        );
}
