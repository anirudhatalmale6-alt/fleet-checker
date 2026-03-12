import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/van_model.dart';
import '../../models/accident_report_model.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../theme/app_theme.dart';

/// Accent colour for accident reports – orange/amber.
const Color _accidentAccent = Color(0xFFFF9800);
const Color _accidentAccentLight = Color(0xFFFFB74D);

class AccidentReportScreen extends StatefulWidget {
  final Van van;
  const AccidentReportScreen({super.key, required this.van});

  @override
  State<AccidentReportScreen> createState() => _AccidentReportScreenState();
}

class _AccidentReportScreenState extends State<AccidentReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _thirdPartyNameCtrl = TextEditingController();
  final _thirdPartyPhoneCtrl = TextEditingController();
  final _thirdPartyVehicleCtrl = TextEditingController();
  final _thirdPartyInsuranceCtrl = TextEditingController();
  final _witnessCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  AccidentSeverity _severity = AccidentSeverity.minor;
  final List<Uint8List> _photos = [];
  bool _submitting = false;
  bool _showThirdParty = false;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 50,
    );
    for (final img in images) {
      final bytes = await img.readAsBytes();
      setState(() => _photos.add(bytes));
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 50,
    );
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() => _photos.add(bytes));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final auth = context.read<AuthService>();
    final data = context.read<DataService>();
    final user = auth.currentUser!;

    try {
      await data.addAccidentReport(
        vanId: widget.van.id,
        vanRegistration: widget.van.registration,
        driverId: user.id,
        driverName: user.name,
        ownerId: widget.van.ownerId,
        location: _locationCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        severity: _severity,
        photoBytes: _photos,
        thirdPartyName: _thirdPartyNameCtrl.text.trim().isNotEmpty
            ? _thirdPartyNameCtrl.text.trim()
            : null,
        thirdPartyPhone: _thirdPartyPhoneCtrl.text.trim().isNotEmpty
            ? _thirdPartyPhoneCtrl.text.trim()
            : null,
        thirdPartyVehicle: _thirdPartyVehicleCtrl.text.trim().isNotEmpty
            ? _thirdPartyVehicleCtrl.text.trim()
            : null,
        thirdPartyInsurance: _thirdPartyInsuranceCtrl.text.trim().isNotEmpty
            ? _thirdPartyInsuranceCtrl.text.trim()
            : null,
        witnessDetails: _witnessCtrl.text.trim().isNotEmpty
            ? _witnessCtrl.text.trim()
            : null,
        notes: _notesCtrl.text.trim().isNotEmpty
            ? _notesCtrl.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accident report submitted'),
            backgroundColor: _accidentAccent,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    _thirdPartyNameCtrl.dispose();
    _thirdPartyPhoneCtrl.dispose();
    _thirdPartyVehicleCtrl.dispose();
    _thirdPartyInsuranceCtrl.dispose();
    _witnessCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Accident'),
        backgroundColor: _accidentAccent.withValues(alpha: 0.3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _accidentAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _accidentAccent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.van.registration,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '${widget.van.make} ${widget.van.model}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Location
                  const _SectionLabel(
                      text: 'Location', icon: Icons.location_on),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _locationCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Where did the accident happen?',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const _SectionLabel(
                      text: 'What happened?', icon: Icons.description),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Describe what happened...',
                    ),
                    maxLines: 4,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  // Severity
                  const _SectionLabel(
                      text: 'Severity', icon: Icons.warning_amber),
                  const SizedBox(height: 8),
                  Row(
                    children: AccidentSeverity.values.map((s) {
                      final selected = _severity == s;
                      final color = s == AccidentSeverity.minor
                          ? AppTheme.success
                          : s == AccidentSeverity.moderate
                              ? _accidentAccent
                              : AppTheme.danger;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right:
                                  s != AccidentSeverity.major ? 8 : 0),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _severity = s),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              decoration: BoxDecoration(
                                color: selected
                                    ? color.withValues(alpha: 0.25)
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
                              child: Column(
                                children: [
                                  Icon(
                                    s == AccidentSeverity.minor
                                        ? Icons.info_outline
                                        : s == AccidentSeverity.moderate
                                            ? Icons.warning_amber_rounded
                                            : Icons.dangerous,
                                    color: selected
                                        ? color
                                        : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    s == AccidentSeverity.minor
                                        ? 'Minor'
                                        : s == AccidentSeverity.moderate
                                            ? 'Moderate'
                                            : 'Major',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? color
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Photos
                  const _SectionLabel(
                      text: 'Photos of Damage', icon: Icons.camera_alt),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._photos.asMap().entries.map((entry) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                entry.value,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: -4,
                              right: -4,
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _photos.removeAt(entry.key)),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: AppTheme.danger,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 18, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      GestureDetector(
                        onTap: _takePhoto,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _accidentAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: _accidentAccent
                                    .withValues(alpha: 0.4)),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt,
                                  color: _accidentAccent, size: 24),
                              Text('Camera',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: _accidentAccent)),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _pickPhoto,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _accidentAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: _accidentAccent
                                    .withValues(alpha: 0.4)),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_library,
                                  color: _accidentAccent, size: 24),
                              Text('Gallery',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: _accidentAccent)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Third party toggle
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showThirdParty = !_showThirdParty),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _showThirdParty
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: _accidentAccentLight,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Third Party Details (optional)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showThirdParty) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _thirdPartyNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Other driver name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _thirdPartyPhoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Other driver phone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _thirdPartyVehicleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Other vehicle registration',
                        prefixIcon: Icon(Icons.directions_car_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _thirdPartyInsuranceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Other driver insurance details',
                        prefixIcon: Icon(Icons.shield_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _witnessCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Witness details',
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                      maxLines: 2,
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Additional notes
                  const _SectionLabel(
                      text: 'Additional Notes', icon: Icons.notes),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Any other details...',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accidentAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                          _submitting ? 'Submitting...' : 'Submit Report'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  const _SectionLabel({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _accidentAccent, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
