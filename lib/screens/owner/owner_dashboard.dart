import 'package:flutter/material.dart';
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
                              icon: Icons.warning,
                              label: 'Failed',
                              value: '${failedInspections.length}',
                              color: AppTheme.danger,
                            ),
                          ],
                        ),
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
