import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../models/inspection_model.dart';
import '../../services/pdf_report_service.dart';
import '../../theme/app_theme.dart';

/// Returns an Image widget that handles both URLs and base64 strings.
Widget buildPhotoImage(String data, {BoxFit fit = BoxFit.cover, double? width, double? height, Widget Function(BuildContext, Object, StackTrace?)? errorBuilder}) {
  if (data.startsWith('http')) {
    return Image.network(
      data,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          color: AppTheme.cardBg,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: errorBuilder ?? (_, __, ___) => Container(
        width: width,
        height: height,
        color: AppTheme.cardBg,
        child: const Center(child: Icon(Icons.broken_image, color: AppTheme.textSecondary)),
      ),
    );
  } else {
    try {
      final bytes = base64Decode(data);
      return Image.memory(
        Uint8List.fromList(bytes),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder ?? (_, __, ___) => Container(
          width: width,
          height: height,
          color: AppTheme.cardBg,
          child: const Center(child: Icon(Icons.broken_image, color: AppTheme.textSecondary)),
        ),
      );
    } catch (_) {
      return Container(
        width: width,
        height: height,
        color: AppTheme.cardBg,
        child: const Center(child: Icon(Icons.broken_image, color: AppTheme.textSecondary)),
      );
    }
  }
}

class InspectionDetailScreen extends StatelessWidget {
  final Inspection inspection;
  const InspectionDetailScreen({super.key, required this.inspection});

  @override
  Widget build(BuildContext context) {
    final isPassed = inspection.status == InspectionStatus.passed;

    return Scaffold(
      appBar: AppBar(
        title: Text('Inspection - ${inspection.vanRegistration}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Download PDF Report',
            onPressed: () => _downloadPdf(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isPassed ? AppTheme.success : AppTheme.danger)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isPassed ? AppTheme.success : AppTheme.danger)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPassed ? Icons.check_circle : Icons.warning,
                    color: isPassed ? AppTheme.success : AppTheme.danger,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isPassed ? 'PASSED' : 'FAILED',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isPassed ? AppTheme.success : AppTheme.danger,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Details
            _Section(
              title: 'Details',
              children: [
                _DetailRow('Van', inspection.vanRegistration),
                _DetailRow('Driver', inspection.driverName),
                _DetailRow('Date',
                    DateFormat('dd MMM yyyy, HH:mm').format(inspection.date)),
                _DetailRow('Mileage', '${inspection.mileage} miles'),
              ],
            ),
            const SizedBox(height: 20),

            // Checklist
            _Section(
              title: 'Checklist Results',
              children: inspection.checklist
                  .map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _statusIcon(item.status),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500)),
                                      if (item.notes != null &&
                                          item.notes!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(item.notes!,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.danger)),
                                      ],
                                    ],
                                  ),
                                ),
                                Text(
                                  item.status.name.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: item.status == CheckStatus.pass
                                        ? AppTheme.success
                                        : item.status == CheckStatus.fail
                                            ? AppTheme.danger
                                            : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            // Per-item photos
                            if (item.photoUrls.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 60,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: item.photoUrls.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 36, right: 6),
                                      child: GestureDetector(
                                        onTap: () => _showFullPhoto(
                                            context, item.photoUrls, index),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: buildPhotoImage(
                                            item.photoUrls[index],
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              width: 60,
                                              height: 60,
                                              color: AppTheme.cardBg,
                                              child: const Icon(Icons.broken_image,
                                                  size: 20,
                                                  color: AppTheme.textSecondary),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ))
                  .toList(),
            ),

            if (inspection.generalNotes != null) ...[
              const SizedBox(height: 20),
              _Section(
                title: 'Notes',
                children: [
                  Text(inspection.generalNotes!,
                      style: const TextStyle(color: AppTheme.textPrimary)),
                ],
              ),
            ],

            // Photos section
            if (inspection.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Photos (${inspection.photoUrls.length})',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: inspection.photoUrls.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _showFullPhoto(context, inspection.photoUrls, index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: buildPhotoImage(
                        inspection.photoUrls[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ],

            // Signature section
            if (inspection.signatureUrl != null) ...[
              const SizedBox(height: 20),
              const Text('Driver Signature',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: buildPhotoImage(
                  inspection.signatureUrl!,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 80,
                    alignment: Alignment.center,
                    child: const Text('Signature unavailable',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem('Passed', '${inspection.passCount}',
                      AppTheme.success),
                  _SummaryItem('Failed', '${inspection.failCount}',
                      AppTheme.danger),
                  _SummaryItem(
                      'N/A',
                      '${inspection.checklist.where((c) => c.status == CheckStatus.na).length}',
                      AppTheme.textSecondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext context) async {
    try {
      final pdf =
          await PdfReportService.generateInspectionReport(inspection);
      final bytes = await pdf.save();
      final fileName =
          'Inspection_${inspection.vanRegistration}_${DateFormat('yyyy-MM-dd').format(inspection.date)}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }

  void _showFullPhoto(BuildContext context, List<String> urls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhotoViewer(urls: urls, initialIndex: initialIndex),
      ),
    );
  }

  Widget _statusIcon(CheckStatus status) {
    switch (status) {
      case CheckStatus.pass:
        return const Icon(Icons.check_circle, color: AppTheme.success, size: 24);
      case CheckStatus.fail:
        return const Icon(Icons.cancel, color: AppTheme.danger, size: 24);
      case CheckStatus.na:
        return const Icon(Icons.remove_circle,
            color: AppTheme.textSecondary, size: 24);
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13)),
      ],
    );
  }
}

class _PhotoViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const _PhotoViewer({required this.urls, required this.initialIndex});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Photo ${_currentIndex + 1} of ${widget.urls.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: buildPhotoImage(
                widget.urls[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
