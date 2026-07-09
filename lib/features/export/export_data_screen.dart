import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers/database_provider.dart';
import '../../core/services/data_export_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/mk_screen_header.dart';

class ExportDataScreen extends ConsumerStatefulWidget {
  const ExportDataScreen({super.key});

  @override
  ConsumerState<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends ConsumerState<ExportDataScreen> {
  bool _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final service = DataExportService(ref.read(databaseProvider));
      final file = await service.buildExportFile();
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: 'MedKit — експорт даних',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const MkScreenHeader(title: 'Експорт даних'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _busy
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.ios_share_rounded,
                              size: 48, color: AppColors.primary),
                          const SizedBox(height: 16),
                          Text('Копія всіх ваших даних', style: AppTextStyles.h2),
                          const SizedBox(height: 8),
                          Text(
                            'Файл у форматі JSON з усіма профілями, ліками, '
                            'розкладом, прийомами, самопочуттям і записами до '
                            'лікарів — усе, що зберігається на цьому пристрої. '
                            'Ви можете відкрити його будь-де або передати кому '
                            'завгодно.\n\n'
                            'Фото ліків у файл не входять (вони вже є у '
                            '«Резервній копії») — лише текстові дані.',
                            style: AppTextStyles.bodyMd
                                .copyWith(color: AppColors.textSub),
                          ),
                          const SizedBox(height: 28),
                          FilledButton.icon(
                            onPressed: _export,
                            icon: const Icon(Icons.download_rounded),
                            label: const Text('Експортувати'),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
