import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/van_model.dart';
import '../../models/inspection_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../services/web_notification_helper.dart';
import '../../theme/app_theme.dart';
import 'van_list_screen.dart';
import 'driver_list_screen.dart';
import 'inspection_list_screen.dart';
import 'settings_screen.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int? _lastKnownInspectionCount;
  int _todayNewCount = 0;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    final user = context.read<AuthService>().currentUser;
    if (user != null && user.notifyPush) {
      await WebNotificationHelper.requestPermission();
    }
  }

  void _onInspectionsUpdated(List<Inspection> inspections) {
    if (_lastKnownInspectionCount == null) {
      _lastKnownInspectionCount = inspections.length;
      return;
    }

    if (inspections.length > _lastKnownInspectionCount!) {
      final newCount = inspections.length - _lastKnownInspectionCount!;
      _todayNewCount += newCount;

      final user = context.read<AuthService>().currentUser;
      if (user != null && user.notifyPush) {
        final newest = inspections.first;
        WebNotificationHelper.show(
          'New Inspection Submitted',
          body:
              '${newest.driverName} inspected ${newest.vanRegistration} — ${newest.status.name.toUpperCase()}',
        );
      }
    }
    _lastKnownInspectionCount = inspections.length;
  }

  void _showEditProfileDialog(
      BuildContext context, AuthService auth, AppUser user) {
    final nameCtrl = TextEditingController(text: user.name);
    final companyCtrl = TextEditingController(text: user.companyName ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: companyCtrl,
              decoration: const InputDecoration(
                labelText: 'Company Name',
                prefixIcon: Icon(Icons.business_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = <String, dynamic>{};
              final newName = nameCtrl.text.trim();
              final newCompany = companyCtrl.text.trim();
              if (newName.isNotEmpty && newName != user.name) {
                data['name'] = newName;
              }
              if (newCompany != (user.companyName ?? '')) {
                data['companyName'] = newCompany.isEmpty ? null : newCompany;
              }
              if (data.isNotEmpty) {
                await auth.updateProfile(data);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

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
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () => _showEditProfileDialog(context, auth, user),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          // Notification bell with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Inspections',
                onPressed: () {
                  setState(() => _todayNewCount = 0);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const InspectionListScreen()));
                },
              ),
              if (_todayNewCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.danger,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '$_todayNewCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
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

                  // Check for new inspections and trigger notifications
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _onInspectionsUpdated(inspections);
                  });

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
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user.companyName != null &&
                            user.companyName!.isNotEmpty)
                          Text(
                            user.companyName!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.accentLight,
                            ),
                          ),
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
                        // Inspection Summary with Percentages
                        ..._buildInspectionSummary(inspections, vans, overdueCount),
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
                  ),
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

List<Widget> _buildInspectionSummary(
    List<Inspection> inspections, List<Van> vans, int overdueCount) {
  if (inspections.isEmpty && vans.isEmpty) return [];

  final total = inspections.length;
  final passed =
      inspections.where((i) => i.status == InspectionStatus.passed).length;
  final failed =
      inspections.where((i) => i.status == InspectionStatus.failed).length;

  final now = DateTime.now();
  final completedToday = inspections
      .where((i) =>
          i.date.year == now.year &&
          i.date.month == now.month &&
          i.date.day == now.day)
      .length;
  final assignedVans = vans.where((v) => v.assignedDriverId != null).length;

  double pct(int count, int of) => of > 0 ? (count / of * 100) : 0;

  // Per-checklist-item failure rates
  final itemFailCounts = <String, int>{};
  final itemTotalCounts = <String, int>{};
  for (final insp in inspections) {
    for (final item in insp.checklist) {
      itemTotalCounts[item.name] = (itemTotalCounts[item.name] ?? 0) + 1;
      if (item.status == CheckStatus.fail) {
        itemFailCounts[item.name] = (itemFailCounts[item.name] ?? 0) + 1;
      }
    }
  }

  return [
    const SizedBox(height: 28),
    const Text(
      'Inspection Summary',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    ),
    const SizedBox(height: 16),

    // Status cards grid (like DAVIS Fleet)
    Row(
      children: [
        _SummaryCard(
          icon: Icons.check_circle,
          label: 'Passed',
          count: passed,
          color: AppTheme.success,
        ),
        const SizedBox(width: 10),
        _SummaryCard(
          icon: Icons.warning,
          label: 'Failed',
          count: failed,
          color: AppTheme.danger,
        ),
        const SizedBox(width: 10),
        _SummaryCard(
          icon: Icons.schedule,
          label: 'Overdue',
          count: overdueCount,
          color: AppTheme.warning,
        ),
      ],
    ),
    const SizedBox(height: 20),

    // Progress bars with percentages
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProgressRow(
            label: 'Total inspections',
            count: total,
            percentage: 100,
            color: AppTheme.accent,
          ),
          const SizedBox(height: 14),
          _ProgressRow(
            label: 'Passed inspections',
            count: passed,
            percentage: pct(passed, total),
            color: AppTheme.success,
          ),
          const SizedBox(height: 14),
          _ProgressRow(
            label: 'Failed inspections',
            count: failed,
            percentage: pct(failed, total),
            color: AppTheme.danger,
          ),
          const SizedBox(height: 14),
          _ProgressRow(
            label: 'Completed today',
            count: completedToday,
            percentage: assignedVans > 0
                ? pct(completedToday, assignedVans)
                : 0,
            color: AppTheme.accentLight,
          ),
          const SizedBox(height: 14),
          _ProgressRow(
            label: 'Vehicles overdue',
            count: overdueCount,
            percentage: assignedVans > 0
                ? pct(overdueCount, assignedVans)
                : 0,
            color: AppTheme.warning,
          ),

          // Top failing items
          if (itemFailCounts.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Top Failing Items',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            ...(() {
              final sorted = itemFailCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              return sorted.take(5).map((e) {
                final itemTotal = itemTotalCounts[e.key] ?? 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ProgressRow(
                    label: e.key,
                    count: e.value,
                    percentage: pct(e.value, itemTotal),
                    color: AppTheme.danger,
                  ),
                );
              });
            })(),
          ],
        ],
      ),
    ),
  ];
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int count;
  final double percentage;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.count,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: AppTheme.surface,
                  color: color,
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: Text(
                '$count – ${percentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
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
