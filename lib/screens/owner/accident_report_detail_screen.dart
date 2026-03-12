import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/accident_report_model.dart';
import '../../services/data_service.dart';
import '../../theme/app_theme.dart';
import '../shared/inspection_detail_screen.dart'; // for buildPhotoImage

const Color _accidentAccent = Color(0xFFFF9800);

class AccidentReportDetailScreen extends StatefulWidget {
  final AccidentReport report;
  const AccidentReportDetailScreen({super.key, required this.report});

  @override
  State<AccidentReportDetailScreen> createState() =>
      _AccidentReportDetailScreenState();
}

class _AccidentReportDetailScreenState
    extends State<AccidentReportDetailScreen> {
  late AccidentStatus _status;

  @override
  void initState() {
    super.initState();
    _status = widget.report.status;
  }

  Future<void> _updateStatus(AccidentStatus newStatus) async {
    final data = context.read<DataService>();
    await data.updateAccidentReport(
        widget.report.id, {'status': newStatus.name});
    setState(() => _status = newStatus);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${newStatus.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final severityColor = report.severity == AccidentSeverity.minor
        ? AppTheme.success
        : report.severity == AccidentSeverity.moderate
            ? _accidentAccent
            : AppTheme.danger;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accident Details'),
        backgroundColor: _accidentAccent.withValues(alpha: 0.3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _accidentAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _accidentAccent.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _accidentAccent.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.car_crash,
                                color: _accidentAccent, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  report.vanRegistration,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Reported by ${report.driverName}',
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: severityColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              report.severityLabel,
                              style: TextStyle(
                                color: severityColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm')
                                .format(report.date),
                            style: const TextStyle(
                                color: AppTheme.textSecondary),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.location_on,
                              size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              report.location,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Status control
                const _Label(text: 'Status'),
                const SizedBox(height: 8),
                Row(
                  children: AccidentStatus.values.map((s) {
                    final selected = _status == s;
                    final color = s == AccidentStatus.resolved
                        ? AppTheme.success
                        : s == AccidentStatus.inProgress
                            ? _accidentAccent
                            : AppTheme.textSecondary;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: s != AccidentStatus.resolved ? 8 : 0),
                        child: GestureDetector(
                          onTap: () => _updateStatus(s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? color.withValues(alpha: 0.2)
                                  : AppTheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? color
                                    : AppTheme.textSecondary
                                        .withValues(alpha: 0.3),
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                s == AccidentStatus.reported
                                    ? 'Reported'
                                    : s == AccidentStatus.inProgress
                                        ? 'In Progress'
                                        : 'Resolved',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? color : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Description
                const _Label(text: 'Description'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    report.description,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, height: 1.5),
                  ),
                ),
                const SizedBox(height: 20),

                // Photos
                if (report.photoUrls.isNotEmpty) ...[
                  const _Label(text: 'Photos'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: report.photoUrls.map((url) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: GestureDetector(
                          onTap: () => _showFullPhoto(context, url),
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: buildPhotoImage(url, fit: BoxFit.cover),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Third party details
                if (report.thirdPartyName != null ||
                    report.thirdPartyPhone != null ||
                    report.thirdPartyVehicle != null ||
                    report.thirdPartyInsurance != null) ...[
                  const _Label(text: 'Third Party Details'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (report.thirdPartyName != null)
                          _DetailRow(
                              label: 'Name', value: report.thirdPartyName!),
                        if (report.thirdPartyPhone != null)
                          _DetailRow(
                              label: 'Phone', value: report.thirdPartyPhone!),
                        if (report.thirdPartyVehicle != null)
                          _DetailRow(
                              label: 'Vehicle',
                              value: report.thirdPartyVehicle!),
                        if (report.thirdPartyInsurance != null)
                          _DetailRow(
                              label: 'Insurance',
                              value: report.thirdPartyInsurance!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Witness
                if (report.witnessDetails != null) ...[
                  const _Label(text: 'Witness Details'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(report.witnessDetails!,
                        style: const TextStyle(color: AppTheme.textPrimary)),
                  ),
                  const SizedBox(height: 20),
                ],

                // Insurance ref
                if (report.insuranceRef != null) ...[
                  const _Label(text: 'Insurance Reference'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(report.insuranceRef!,
                        style: const TextStyle(color: AppTheme.textPrimary)),
                  ),
                  const SizedBox(height: 20),
                ],

                // Notes
                if (report.notes != null) ...[
                  const _Label(text: 'Additional Notes'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(report.notes!,
                        style: const TextStyle(color: AppTheme.textPrimary)),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFullPhoto(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: buildPhotoImage(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _accidentAccent,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }
}
