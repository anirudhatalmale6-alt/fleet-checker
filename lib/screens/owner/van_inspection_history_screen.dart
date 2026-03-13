import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/van_model.dart';
import '../../models/inspection_model.dart';
import '../../services/data_service.dart';
import '../../theme/app_theme.dart';
import '../shared/inspection_detail_screen.dart';

class VanInspectionHistoryScreen extends StatelessWidget {
  final Van van;

  const VanInspectionHistoryScreen({super.key, required this.van});

  @override
  Widget build(BuildContext context) {
    final data = context.read<DataService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(van.registration),
      ),
      body: StreamBuilder<List<Inspection>>(
        stream: data.watchInspectionsForVan(van.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final inspections = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              // Van info header + stats
              SliverToBoxAdapter(
                child: _VanHeader(van: van, inspections: inspections),
              ),
              // Inspection list
              if (inspections.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined,
                            size: 64,
                            color:
                                AppTheme.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text('No inspections yet',
                            style: TextStyle(
                                fontSize: 18, color: AppTheme.textSecondary)),
                        const SizedBox(height: 8),
                        const Text(
                            'Inspections for this vehicle will appear here',
                            style: TextStyle(
                                fontSize: 14, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final insp = inspections[index];
                        final isPassed =
                            insp.status == InspectionStatus.passed;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => InspectionDetailScreen(
                                        inspection: insp))),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: (isPassed
                                              ? AppTheme.success
                                              : AppTheme.danger)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isPassed
                                          ? Icons.check_circle
                                          : Icons.warning,
                                      color: isPassed
                                          ? AppTheme.success
                                          : AppTheme.danger,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            DateFormat('dd MMM yyyy, HH:mm')
                                                .format(insp.date),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15)),
                                        const SizedBox(height: 2),
                                        Text('Driver: ${insp.driverName}',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color:
                                                    AppTheme.textSecondary)),
                                        const SizedBox(height: 2),
                                        Text(
                                            'Mileage: ${insp.mileage}',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color:
                                                    AppTheme.textSecondary)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            _MiniChip(
                                                '${insp.passCount} Pass',
                                                AppTheme.success),
                                            const SizedBox(width: 8),
                                            if (insp.failCount > 0)
                                              _MiniChip(
                                                  '${insp.failCount} Fail',
                                                  AppTheme.danger),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right,
                                      color: AppTheme.textSecondary),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: inspections.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _VanHeader extends StatelessWidget {
  final Van van;
  final List<Inspection> inspections;

  const _VanHeader({required this.van, required this.inspections});

  @override
  Widget build(BuildContext context) {
    final total = inspections.length;
    final passed =
        inspections.where((i) => i.status == InspectionStatus.passed).length;
    final failed =
        inspections.where((i) => i.status == InspectionStatus.failed).length;
    final passRate =
        total > 0 ? (passed / total * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Van details card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.local_shipping,
                        color: AppTheme.accent, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(van.registration,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20)),
                        const SizedBox(height: 4),
                        Text('${van.make} ${van.model}',
                            style: const TextStyle(
                                fontSize: 14, color: AppTheme.textSecondary)),
                        if (van.assignedDriverName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                                'Driver: ${van.assignedDriverName}',
                                style: const TextStyle(
                                    fontSize: 13, color: AppTheme.success)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              _StatCard(
                  label: 'Total',
                  value: '$total',
                  color: AppTheme.accent),
              const SizedBox(width: 8),
              _StatCard(
                  label: 'Passed',
                  value: '$passed',
                  color: AppTheme.success),
              const SizedBox(width: 8),
              _StatCard(
                  label: 'Failed',
                  value: '$failed',
                  color: AppTheme.danger),
              const SizedBox(width: 8),
              _StatCard(
                  label: 'Pass Rate',
                  value: '$passRate%',
                  color: passRate >= 80
                      ? AppTheme.success
                      : passRate >= 50
                          ? AppTheme.warning
                          : AppTheme.danger),
            ],
          ),
          const SizedBox(height: 8),
          // Section title
          if (inspections.isNotEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Inspection History',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary)),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
