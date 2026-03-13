import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/inspection_model.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../theme/app_theme.dart';
import '../shared/inspection_detail_screen.dart';

enum InspectionFilter { all, passed, failed }

class InspectionListScreen extends StatefulWidget {
  final InspectionFilter initialFilter;

  const InspectionListScreen({
    super.key,
    this.initialFilter = InspectionFilter.all,
  });

  @override
  State<InspectionListScreen> createState() => _InspectionListScreenState();
}

class _InspectionListScreenState extends State<InspectionListScreen> {
  late InspectionFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  String get _title {
    switch (_filter) {
      case InspectionFilter.passed:
        return 'Passed Inspections';
      case InspectionFilter.failed:
        return 'Failed Inspections';
      case InspectionFilter.all:
        return 'Inspection Reports';
    }
  }

  List<Inspection> _applyFilter(List<Inspection> inspections) {
    switch (_filter) {
      case InspectionFilter.passed:
        return inspections
            .where((i) => i.status == InspectionStatus.passed)
            .toList();
      case InspectionFilter.failed:
        return inspections
            .where((i) => i.status == InspectionStatus.failed)
            .toList();
      case InspectionFilter.all:
        return inspections;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final data = context.read<DataService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          PopupMenuButton<InspectionFilter>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onSelected: (f) => setState(() => _filter = f),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: InspectionFilter.all,
                child: Row(
                  children: [
                    Icon(Icons.list,
                        size: 18,
                        color: _filter == InspectionFilter.all
                            ? AppTheme.accent
                            : AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    const Text('All'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: InspectionFilter.passed,
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 18,
                        color: _filter == InspectionFilter.passed
                            ? AppTheme.success
                            : AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    const Text('Passed'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: InspectionFilter.failed,
                child: Row(
                  children: [
                    Icon(Icons.warning,
                        size: 18,
                        color: _filter == InspectionFilter.failed
                            ? AppTheme.danger
                            : AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    const Text('Failed'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Inspection>>(
        stream: data.watchInspectionsForOwner(auth.currentUser!.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final allInspections = snapshot.data ?? [];
          final inspections = _applyFilter(allInspections);

          if (inspections.isEmpty) {
            final emptyMsg = _filter == InspectionFilter.all
                ? 'No inspections yet'
                : 'No ${_filter.name} inspections';
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 64,
                      color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(emptyMsg,
                      style: const TextStyle(
                          fontSize: 18, color: AppTheme.textSecondary)),
                  if (_filter != InspectionFilter.all) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () =>
                          setState(() => _filter = InspectionFilter.all),
                      child: const Text('Show all inspections'),
                    ),
                  ],
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: inspections.length,
            itemBuilder: (context, index) {
              final insp = inspections[index];
              final isPassed = insp.status == InspectionStatus.passed;
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
                                    _MiniChip('${insp.failCount} Fail',
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
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
