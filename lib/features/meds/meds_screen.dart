import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/models/medication.dart';
import 'add_med_sheet.dart';
import 'widgets/med_list_tile.dart';

class MedsScreen extends StatefulWidget {
  const MedsScreen({super.key});

  @override
  State<MedsScreen> createState() => _MedsScreenState();
}

class _MedsScreenState extends State<MedsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final List<Medication> _meds = <Medication>[
    Medication(
      id: 'm1',
      name: 'Еналаприл',
      form: MedForm.tablet,
      dose: '10 мг',
      foodRelation: FoodRelation.any,
      totalCount: 30,
      remainingCount: 22,
      createdAt: DateTime.now(),
    ),
    Medication(
      id: 'm2',
      name: 'Метформін',
      form: MedForm.tablet,
      dose: '500 мг',
      foodRelation: FoodRelation.after,
      totalCount: 60,
      remainingCount: 8,
      createdAt: DateTime.now(),
    ),
    Medication(
      id: 'm3',
      name: 'Омега-3',
      form: MedForm.capsule,
      dose: '1 капсула',
      foodRelation: FoodRelation.with_,
      totalCount: 90,
      remainingCount: 45,
      createdAt: DateTime.now(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _openAddSheet() {
    final l10n = context.l10n;
    final activeMeds = _meds.where((m) => m.isActive).length;

    if (!AppConfig.canAddUnlimitedMeds &&
        activeMeds >= AppConfig.freeMedsLimit) {
      _showLimitDialog(l10n);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMedSheet(
        onSave: (med) => setState(() => _meds.add(med)),
      ),
    );
  }

  void _showLimitDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        title: Text(l10n.medsFreeLimitTitle,
            style: AppTextStyles.h3),
        content: Text(
            l10n.medsFreeLimitBody(AppConfig.freeMedsLimit),
            style: AppTextStyles.bodyMd),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.actionCancel,
                style:
                    TextStyle(color: AppColors.textSub)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.proGold),
            child: Text(l10n.proUpgradeButton),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final active = _meds.where((m) => m.isActive).toList();
    final archived = _meds.where((m) => !m.isActive).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: NestedScrollView(
        headerSliverBuilder: (context2, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.bg,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(l10n.medsTitle, style: AppTextStyles.h3),
            bottom: TabBar(
              controller: _tabCtrl,
              labelStyle: AppTextStyles.labelMd,
              unselectedLabelStyle: AppTextStyles.bodyMd,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(text: l10n.medsActive),
                Tab(text: l10n.medsArchived),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _MedsList(
              meds: active,
              emptyTitle: l10n.medsEmpty,
              emptyHint: l10n.medsEmptyHint,
            ),
            _MedsList(
              meds: archived,
              emptyTitle: l10n.medsArchived,
              emptyHint: l10n.comingSoon,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _MedsList extends StatelessWidget {
  final List<Medication> meds;
  final String emptyTitle;
  final String emptyHint;

  const _MedsList({
    required this.meds,
    required this.emptyTitle,
    required this.emptyHint,
  });

  @override
  Widget build(BuildContext context) {
    if (meds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💊', style: TextStyle(fontSize: 48)),
              const SizedBox(height: AppDimensions.lg),
              Text(emptyTitle,
                  style: AppTextStyles.h3,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppDimensions.sm),
              Text(emptyHint,
                  style: AppTextStyles.bodyMd,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      itemCount: meds.length,
      itemBuilder: (_, i) => MedListTile(med: meds[i]),
    );
  }
}
