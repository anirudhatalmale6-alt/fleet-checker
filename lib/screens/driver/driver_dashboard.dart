import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/van_model.dart';
import '../../models/inspection_model.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../theme/app_theme.dart';
import 'inspection_flow_screen.dart';
import '../shared/inspection_detail_screen.dart';

class DriverDashboard extends StatelessWidget {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final data = context.read<DataService>();
    final user = auth.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Checker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user.name}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ready for today\'s inspection?',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Assigned Vans with overdue warnings
            StreamBuilder<List<Van>>(
              stream: data.watchVansForDriver(user.id),
              builder: (context, vanSnapshot) {
                final myVans = vanSnapshot.data ?? [];
                if (myVans.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.local_shipping_outlined,
                            size: 48,
                            color:
                                AppTheme.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        const Text('No vans assigned to you yet',
                            style:
                                TextStyle(color: AppTheme.textSecondary)),
                        const Text('Ask your manager to assign a van',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13)),
                      ],
                    ),
                  );
                }
                return StreamBuilder<List<Inspection>>(
                  stream: data.watchInspectionsForDriver(user.id),
                  builder: (context, inspSnapshot) {
                    final allInspections = inspSnapshot.data ?? [];
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);

                    // Calculate overdue status per van
                    bool isVanOverdue(Van van) {
                      final vanInsps = allInspections
                          .where((i) => i.vanId == van.id)
                          .toList()
                        ..sort((a, b) => b.date.compareTo(a.date));
                      if (vanInsps.isEmpty) return true;
                      final ld = vanInsps.first.date;
                      final daysSince = today
                          .difference(DateTime(ld.year, ld.month, ld.day))
                          .inDays;
                      return daysSince >= van.inspectionFrequencyDays;
                    }

                    int daysOverdue(Van van) {
                      final vanInsps = allInspections
                          .where((i) => i.vanId == van.id)
                          .toList()
                        ..sort((a, b) => b.date.compareTo(a.date));
                      if (vanInsps.isEmpty) {
                        return today
                            .difference(DateTime(van.createdAt.year,
                                van.createdAt.month, van.createdAt.day))
                            .inDays;
                      }
                      final ld = vanInsps.first.date;
                      return today
                          .difference(DateTime(ld.year, ld.month, ld.day))
                          .inDays;
                    }

                    final overdueVans =
                        myVans.where((v) => isVanOverdue(v)).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overdue alert banner
                        if (overdueVans.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      AppTheme.danger.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.notification_important,
                                    color: AppTheme.danger, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${overdueVans.length} vehicle${overdueVans.length == 1 ? "" : "s"} overdue',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppTheme.danger,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Please complete your inspection',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        const Text(
                          'Your Vehicles',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        ...myVans.map((van) {
                          final overdue = isVanOverdue(van);
                          final days = daysOverdue(van);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: overdue
                                  ? Border.all(
                                      color: AppTheme.danger
                                          .withValues(alpha: 0.5),
                                      width: 1.5)
                                  : null,
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: overdue
                                          ? AppTheme.danger
                                              .withValues(alpha: 0.15)
                                          : AppTheme.accent
                                              .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      overdue
                                          ? Icons.warning_amber_rounded
                                          : Icons.local_shipping,
                                      color: overdue
                                          ? AppTheme.danger
                                          : AppTheme.accent,
                                    ),
                                  ),
                                  title: Text(van.registration,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('${van.make} ${van.model}',
                                          style: const TextStyle(
                                              color:
                                                  AppTheme.textSecondary)),
                                      if (overdue)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 4),
                                          child: Text(
                                            '$days day${days == 1 ? "" : "s"} overdue!',
                                            style: const TextStyle(
                                              color: AppTheme.danger,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: ElevatedButton(
                                    style: overdue
                                        ? ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.danger)
                                        : null,
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              InspectionFlowScreen(
                                                  van: van)),
                                    ),
                                    child: Text(overdue
                                        ? 'Inspect Now!'
                                        : 'Inspect'),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // Recent Inspections
            StreamBuilder<List<Inspection>>(
              stream: data.watchInspectionsForDriver(user.id),
              builder: (context, snapshot) {
                final recentInspections =
                    (snapshot.data ?? []).take(5).toList();
                if (recentInspections.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Inspections',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    ...recentInspections.map((insp) {
                      final isPassed =
                          insp.status == InspectionStatus.passed;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => InspectionDetailScreen(
                                      inspection: insp))),
                          leading: Icon(
                            isPassed
                                ? Icons.check_circle
                                : Icons.warning,
                            color: isPassed
                                ? AppTheme.success
                                : AppTheme.danger,
                          ),
                          title: Text(insp.vanRegistration),
                          subtitle: Text(DateFormat('dd MMM yyyy, HH:mm')
                              .format(insp.date)),
                          trailing: const Icon(Icons.chevron_right,
                              color: AppTheme.textSecondary),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}
