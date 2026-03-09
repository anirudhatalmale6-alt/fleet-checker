import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/van_model.dart';
import '../../models/inspection_model.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../theme/app_theme.dart';

class InspectionFlowScreen extends StatefulWidget {
  final Van van;
  const InspectionFlowScreen({super.key, required this.van});

  @override
  State<InspectionFlowScreen> createState() => _InspectionFlowScreenState();
}

class _InspectionFlowScreenState extends State<InspectionFlowScreen> {
  int _step = 0; // 0=mileage, 1=checklist, 2=notes, 3=photos, 4=review
  final _mileageCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  late List<ChecklistItem> _checklist;

  // Photo state
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _photos = [];
  final List<Uint8List> _photoThumbnails = [];

  @override
  void initState() {
    super.initState();
    _mileageCtrl.text = widget.van.mileage.toString();
    _checklist = Inspection.defaultChecklist();
  }

  void _next() {
    if (_step == 0) {
      if (_mileageCtrl.text.isEmpty || int.tryParse(_mileageCtrl.text) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter a valid mileage')));
        return;
      }
    }
    setState(() => _step++);
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final images = await _picker.pickMultiImage(
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 80,
        );
        for (final img in images) {
          final bytes = await img.readAsBytes();
          setState(() {
            _photos.add(img);
            _photoThumbnails.add(bytes);
          });
        }
      } else {
        final img = await _picker.pickImage(
          source: source,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 80,
        );
        if (img != null) {
          final bytes = await img.readAsBytes();
          setState(() {
            _photos.add(img);
            _photoThumbnails.add(bytes);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
      _photoThumbnails.removeAt(index);
    });
  }

  bool _submitting = false;

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final auth = context.read<AuthService>();
    final data = context.read<DataService>();
    final user = auth.currentUser!;
    final hasFails = _checklist.any((c) => c.status == CheckStatus.fail);

    await data.addInspection(
      vanId: widget.van.id,
      vanRegistration: widget.van.registration,
      driverId: user.id,
      driverName: user.name,
      ownerId: widget.van.ownerId,
      mileage: int.parse(_mileageCtrl.text),
      checklist: _checklist,
      status: hasFails ? InspectionStatus.failed : InspectionStatus.passed,
      generalNotes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
      photoBytes: _photoThumbnails,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              hasFails ? Icons.warning : Icons.check_circle,
              color: hasFails ? AppTheme.danger : AppTheme.success,
            ),
            const SizedBox(width: 12),
            Text(hasFails ? 'Issues Found' : 'Inspection Passed'),
          ],
        ),
        content: Text(hasFails
            ? 'Inspection submitted with ${_checklist.where((c) => c.status == CheckStatus.fail).length} failed items. Your manager has been notified.'
            : 'All checks passed! Inspection submitted successfully.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inspect ${widget.van.registration}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          _StepIndicator(currentStep: _step),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildStep(),
            ),
          ),
          // Navigation buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _back,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppTheme.accent),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : (_step < 4 ? _next : _submit),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor:
                            _step == 4 ? AppTheme.success : AppTheme.accent,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(_step < 4 ? 'Next' : 'Submit Inspection'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildMileageStep();
      case 1:
        return _buildChecklistStep();
      case 2:
        return _buildNotesStep();
      case 3:
        return _buildPhotosStep();
      case 4:
        return _buildReviewStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildMileageStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 1: Confirm Mileage',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Text('${widget.van.make} ${widget.van.model} - ${widget.van.registration}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
        const SizedBox(height: 32),
        TextFormField(
          controller: _mileageCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            labelText: 'Current Mileage',
            suffixText: 'miles',
            filled: true,
            fillColor: AppTheme.cardBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 2: Vehicle Checklist',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        const Text('Tap each item to mark as Pass, Fail, or N/A',
            style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 20),
        ..._checklist.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: item.status == CheckStatus.fail
                    ? AppTheme.danger.withValues(alpha: 0.5)
                    : item.status == CheckStatus.pass
                        ? AppTheme.success.withValues(alpha: 0.3)
                        : Colors.transparent,
              ),
            ),
            child: ListTile(
              leading: _checkIcon(item.status),
              title: Text(item.name,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              trailing: ToggleButtons(
                isSelected: [
                  item.status == CheckStatus.pass,
                  item.status == CheckStatus.fail,
                  item.status == CheckStatus.na,
                ],
                onPressed: (i) {
                  setState(() {
                    _checklist[idx].status = CheckStatus.values[i];
                  });
                },
                borderRadius: BorderRadius.circular(8),
                selectedColor: Colors.white,
                fillColor: [
                  AppTheme.success,
                  AppTheme.danger,
                  AppTheme.textSecondary,
                ][_checklist[idx].status.index],
                constraints:
                    const BoxConstraints(minWidth: 48, minHeight: 36),
                children: const [
                  Text('Pass', style: TextStyle(fontSize: 12)),
                  Text('Fail', style: TextStyle(fontSize: 12)),
                  Text('N/A', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNotesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 3: Notes & Issues',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        const Text('Add any additional notes or report issues',
            style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 20),
        // Show failed items
        ..._checklist.where((c) => c.status == CheckStatus.fail).map((item) =>
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning,
                          color: AppTheme.danger, size: 18),
                      const SizedBox(width: 8),
                      Text('${item.name} - FAILED',
                          style: const TextStyle(
                              color: AppTheme.danger,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (v) => item.notes = v,
                    decoration: InputDecoration(
                      hintText: 'Describe the issue...',
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            )),
        const SizedBox(height: 16),
        TextField(
          controller: _notesCtrl,
          decoration: InputDecoration(
            labelText: 'General Notes (optional)',
            hintText: 'Any additional observations...',
            filled: true,
            fillColor: AppTheme.cardBg,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildPhotosStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 4: Photos',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        const Text('Add photos of the vehicle or any issues found',
            style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 20),

        // Add photo buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickPhoto(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.accent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickPhoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.accent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Photo count
        if (_photos.isNotEmpty) ...[
          Text('${_photos.length} photo${_photos.length == 1 ? '' : 's'} added',
              style: const TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 15)),
          const SizedBox(height: 12),
        ],

        // Photo grid
        if (_photos.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: Image.memory(
                        _photoThumbnails[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removePhoto(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

        if (_photos.isEmpty) ...[
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Icon(Icons.add_a_photo,
                    size: 64,
                    color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                const Text('No photos added yet',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 16)),
                const SizedBox(height: 4),
                const Text('Photos are optional but recommended',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewStep() {
    final hasFails = _checklist.any((c) => c.status == CheckStatus.fail);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 5: Review & Submit',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 20),
        _reviewRow('Van', widget.van.registration),
        _reviewRow('Make/Model', '${widget.van.make} ${widget.van.model}'),
        _reviewRow('Mileage', '${_mileageCtrl.text} miles'),
        _reviewRow(
            'Date', DateTime.now().toString().substring(0, 16)),
        _reviewRow('Photos', '${_photos.length} photo${_photos.length == 1 ? '' : 's'}'),
        const Divider(color: AppTheme.textSecondary, height: 32),
        const Text('Checklist Results',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        ..._checklist.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  _checkIcon(item.status),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item.name)),
                  Text(
                    item.status.name.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: item.status == CheckStatus.pass
                          ? AppTheme.success
                          : item.status == CheckStatus.fail
                              ? AppTheme.danger
                              : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            )),
        if (_notesCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Notes',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Text(_notesCtrl.text),
              ],
            ),
          ),
        ],

        // Photo thumbnails in review
        if (_photos.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Photos',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _photoThumbnails[index],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (hasFails ? AppTheme.danger : AppTheme.success)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: (hasFails ? AppTheme.danger : AppTheme.success)
                    .withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasFails ? Icons.warning : Icons.check_circle,
                color: hasFails ? AppTheme.danger : AppTheme.success,
              ),
              const SizedBox(width: 8),
              Text(
                hasFails ? 'ISSUES FOUND' : 'ALL CHECKS PASSED',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: hasFails ? AppTheme.danger : AppTheme.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _checkIcon(CheckStatus status) {
    switch (status) {
      case CheckStatus.pass:
        return const Icon(Icons.check_circle, color: AppTheme.success, size: 28);
      case CheckStatus.fail:
        return const Icon(Icons.cancel, color: AppTheme.danger, size: 28);
      case CheckStatus.na:
        return const Icon(Icons.remove_circle, color: AppTheme.textSecondary, size: 28);
    }
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Inspection?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Continue Inspection')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Cancel', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mileageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = ['Mileage', 'Checklist', 'Notes', 'Photos', 'Review'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      color: AppTheme.primary,
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                height: 2,
                color: i ~/ 2 < currentStep
                    ? AppTheme.accent
                    : AppTheme.textSecondary.withValues(alpha: 0.3),
              ),
            );
          }
          final stepIdx = i ~/ 2;
          final isActive = stepIdx <= currentStep;
          final isCurrent = stepIdx == currentStep;
          return Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.accent : AppTheme.surface,
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(color: AppTheme.accentLight, width: 2)
                      : null,
                ),
                child: Center(
                  child: stepIdx < currentStep
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text('${stepIdx + 1}',
                          style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                ),
              ),
              const SizedBox(height: 4),
              Text(steps[stepIdx],
                  style: TextStyle(
                      fontSize: 10,
                      color: isActive ? AppTheme.accent : AppTheme.textSecondary)),
            ],
          );
        }),
      ),
    );
  }
}
