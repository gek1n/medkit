import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/app_colors.dart';
import 'mk_screen_header.dart';

/// Показує юридичний документ (політика конфіденційності/умови
/// використання) із живого сайту через WebView замість окремої копії
/// тексту в застосунку — правки документа редагуються один раз на сайті,
/// без нового релізу застосунку і без ризику розсинхрону версій.
class LegalWebViewScreen extends StatefulWidget {
  final String title;
  final String url;
  const LegalWebViewScreen({super.key, required this.title, required this.url});

  @override
  State<LegalWebViewScreen> createState() => _LegalWebViewScreenState();
}

class _LegalWebViewScreenState extends State<LegalWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.bg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _loading = false;
                _error = 'Не вдалося завантажити сторінку. Перевірте з\'єднання з інтернетом.';
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            MkScreenHeader(title: widget.title),
            Expanded(
              child: _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSub),
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        WebViewWidget(controller: _controller),
                        if (_loading)
                          const Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
