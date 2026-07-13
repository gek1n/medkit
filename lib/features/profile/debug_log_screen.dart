import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/app_logger.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/mk_screen_header.dart';

class DebugLogScreen extends StatefulWidget {
  const DebugLogScreen({super.key});

  @override
  State<DebugLogScreen> createState() => _DebugLogScreenState();
}

class _DebugLogScreenState extends State<DebugLogScreen> {
  String _text = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final text = await AppLogger.readAll();
    if (!mounted) return;
    setState(() {
      _text = text.isEmpty ? 'Лог порожній.' : text;
      _loading = false;
    });
  }

  Future<void> _share() async {
    final file = await AppLogger.exportFile();
    final exists = await file.exists();
    if (!mounted) return;
    if (!exists) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Лог порожній')));
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/plain')],
        subject: 'Elly — журнал подій',
      ),
    );
  }

  Future<void> _clear() async {
    await AppLogger.clear();
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            MkScreenHeader(
              title: 'Журнал подій',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        _text,
                        style: AppTextStyles.bodySm.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _clear,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Очистити'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _share,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.ios_share_rounded),
                      label: const Text('Поділитись'),
                    ),
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
