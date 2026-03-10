import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/van_model.dart';
import '../../models/inspection_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../theme/app_theme.dart';
import 'van_list_screen.dart';
import 'driver_list_screen.dart';
import 'inspection_list_screen.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

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
      body: StreamBuilder<List<Van>>(
        stream: data.watchVansForOwner(user.id),
        builder: (context, vanSnap) {
          final vans = vanSnap.data ?? [];
          return StreamBuilder<List<AppUser>>(
            stream: auth.watchDriversForOwner(user.id),
            builder: (context, driverSnap) {
              final drivers = driverSnap.data ?? [];
              return StreamBuilder<List<Inspection>>(
                stream: data.watchInspectionsForOwner(user.id),
                builder: (context, inspSnap) {
                  final inspections = inspSnap.data ?? [];
                  final today = DateTime.now();
                  final todayInspections = inspections.where((i) =>
                      i.date.year == today.year &&
                      i.date.month == today.month &&
                      i.date.day == today.day).toList();
                  final failedInspections = inspections
                      .where((i) => i.status == InspectionStatus.failed)
                      .toList();

                  // Count overdue vans
                  int overdueCount = 0;
                  for (final van in vans) {
                    if (van.assignedDriverId == null) continue;
                    final vanInsps = inspections
                        .where((i) => i.vanId == van.id)
                        .toList()
                      ..sort((a, b) => b.date.compareTo(a.date));
                    if (vanInsps.isEmpty) {
                      final d = today
                          .difference(DateTime(van.createdAt.year,
                              van.createdAt.month, van.createdAt.day))
                          .inDays;
                      if (d >= van.inspectionFrequencyDays) overdueCount++;
                    } else {
                      final ld = vanInsps.first.date;
                      final d = DateTime(today.year, today.month, today.day)
                          .difference(
                              DateTime(ld.year, ld.month, ld.day))
                          .inDays;
                      if (d >= van.inspectionFrequencyDays) overdueCount++;
                    }
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${user.name}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Fleet Overview',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            _StatCard(
                              icon: Icons.local_shipping,
                              label: 'Vans',
                              value: '${vans.length}',
                              color: AppTheme.accent,
                            ),
                            const SizedBox(width: 12),
                            _StatCard(
                              icon: Icons.people,
                              label: 'Drivers',
                              value: '${drivers.length}',
                              color: AppTheme.accentLight,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _StatCard(
                              icon: Icons.check_circle,
                              label: 'Today',
                              value: '${todayInspections.length}',
                              color: AppTheme.success,
                            ),
                            const SizedBox(width: 12),
                            _StatCard(
                              icon: Icons.notification_important,
                              label: 'Overdue',
                              value: '$overdueCount',
                              color: overdueCount > 0
                                  ? AppTheme.danger
                                  : AppTheme.success,
                            ),
                          ],
                        ),
                        // Overdue Inspections Section
                        ..._buildOverdueSection(vans, inspections),
                        const SizedBox(height: 32),
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ActionTile(
                          icon: Icons.local_shipping,
                          title: 'Manage Vans',
                          subtitle: '${vans.length} vans in fleet',
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const VanListScreen())),
                        ),
                        const SizedBox(height: 12),
                        _ActionTile(
                          icon: Icons.people,
                          title: 'Manage Drivers',
                          subtitle: '${drivers.length} drivers',
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const DriverListScreen())),
                        ),
                        const SizedBox(height: 12),
                        _ActionTile(
                          icon: Icons.assignment,
                          title: 'Inspection Reports',
                          subtitle: 'View all inspection history',
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const InspectionListScreen())),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

List<Widget> _buildOverdueSection(List<Van> vans, List<Inspection> inspections) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Find overdue vans: assigned driver but no recent inspection within frequency
  final overdueVans = <Van, int>{}; // van -> days overdue
  for (final van in vans) {
    if (van.assignedDriverId == null) continue;

    // Find the most recent inspection for this van
    final vanInspections = inspections
        .where((i) => i.vanId == van.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (vanInspections.isEmpty) {
      // Never inspected - overdue since creation
      final daysSinceCreated = today.difference(
          DateTime(van.createdAt.year, van.createdAt.month, van.createdAt.day))
          .inDays;
      if (daysSinceCreated >= van.inspectionFrequencyDays) {
        overdueVans[van] = daysSinceCreated;
      }
    } else {
      final lastDate = vanInspections.first.date;
      final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final daysSince = today.difference(lastDay).inDays;
      if (daysSince >= van.inspectionFrequencyDays) {
        overdueVans[van] = daysSince;
      }
    }
  }

  if (overdueVans.isEmpty) return [];

  return [
    const SizedBox(height: 24),
    Row(
      children: [
        const Icon(Icons.notification_important, color: AppTheme.danger, size: 22),
        const SizedBox(width: 8),
        Text(
          'Overdue Inspections (${overdueVans.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.danger,
          ),
        ),
      ],
    ),
    const SizedBox(height: 12),
    ...overdueVans.entries.map((entry) {
      final van = entry.key;
      final daysOverdue = entry.value;
      final freq = van.inspectionFrequencyDays;
      final freqLabel = freq == 1 ? 'daily' : freq == 7 ? 'weekly' : 'every $freq days';

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.danger, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    van.registration,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${van.assignedDriverName ?? "Unknown driver"} • $daysOverdue day${daysOverdue == 1 ? "" : "s"} overdue',
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  Text(
                    'Expected: $freqLabel inspection',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.danger.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }),
  ];
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
