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

            // Assigned Vans
            StreamBuilder<List<Van>>(
              stream: data.watchVansForDriver(user.id),
              builder: (context, snapshot) {
                final myVans = snapshot.data ?? [];
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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Vehicles',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    ...myVans.map((van) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.local_shipping,
                                  color: AppTheme.accent),
                            ),
                            title: Text(van.registration,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                            subtitle: Text('${van.make} ${van.model}',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary)),
                            trailing: ElevatedButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        InspectionFlowScreen(van: van)),
                              ),
                              child: const Text('Inspect'),
                            ),
                          ),
                        )),
                  ],
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
    );
  }
}
