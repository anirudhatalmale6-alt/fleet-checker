import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/inspection_model.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../theme/app_theme.dart';
import '../shared/inspection_detail_screen.dart';

class InspectionListScreen extends StatelessWidget {
  const InspectionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final data = context.watch<DataService>();
    final inspections = data.getInspectionsForOwner(auth.currentUser!.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Inspection Reports')),
      body: inspections.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 64,
                      color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('No inspections yet',
                      style: TextStyle(
                          fontSize: 18, color: AppTheme.textSecondary)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: inspections.length,
              itemBuilder: (context, index) {
                final insp = inspections[index];
                final isPassed =
                    insp.status == InspectionStatus.passed;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                InspectionDetailScreen(inspection: insp))),
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
                              isPassed ? Icons.check_circle : Icons.warning,
                              color: isPassed
                                  ? AppTheme.success
                                  : AppTheme.danger,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(insp.vanRegistration,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 2),
                                Text(
                                    '${insp.driverName} - ${DateFormat('dd MMM yyyy, HH:mm').format(insp.date)}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary)),
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
          style:
              TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
