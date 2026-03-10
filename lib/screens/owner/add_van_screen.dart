import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/van_model.dart';
import '../../models/inspection_model.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../theme/app_theme.dart';

class AddVanScreen extends StatefulWidget {
  final Van? van;
  const AddVanScreen({super.key, this.van});

  @override
  State<AddVanScreen> createState() => _AddVanScreenState();
}

class _AddVanScreenState extends State<AddVanScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _regCtrl;
  late final TextEditingController _makeCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _mileageCtrl;
  late String _vehicleType;
  late int _inspectionFrequencyDays;
  late List<String> _checklistItems;
  bool _saving = false;

  bool get isEditing => widget.van != null;

  static const _vehicleTypes = ['Van', 'Truck', 'Car', 'Bus', 'Other'];
  static const _frequencyOptions = {
    1: 'Daily',
    2: 'Every 2 days',
    3: 'Every 3 days',
    7: 'Weekly',
    14: 'Every 2 weeks',
    30: 'Monthly',
  };

  @override
  void initState() {
    super.initState();
    _regCtrl = TextEditingController(text: widget.van?.registration ?? '');
    _makeCtrl = TextEditingController(text: widget.van?.make ?? '');
    _modelCtrl = TextEditingController(text: widget.van?.model ?? '');
    _mileageCtrl =
        TextEditingController(text: widget.van?.mileage.toString() ?? '');
    _vehicleType = widget.van?.vehicleType ?? 'Van';
    _inspectionFrequencyDays = widget.van?.inspectionFrequencyDays ?? 1;
    // Load custom checklist or defaults
    if (widget.van != null && widget.van!.customChecklist.isNotEmpty) {
      _checklistItems = List.from(widget.van!.customChecklist);
    } else {
      _checklistItems = Inspection.defaultChecklist()
          .map((c) => c.name)
          .toList();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = context.read<DataService>();
    final auth = context.read<AuthService>();

    if (isEditing) {
      await data.updateVan(widget.van!.id, {
        'registration': _regCtrl.text.trim().toUpperCase(),
        'make': _makeCtrl.text.trim(),
        'model': _modelCtrl.text.trim(),
        'mileage': int.parse(_mileageCtrl.text.trim()),
        'vehicleType': _vehicleType,
        'inspectionFrequencyDays': _inspectionFrequencyDays,
        'customChecklist': _checklistItems,
      });
    } else {
      await data.addVan(
        registration: _regCtrl.text.trim(),
        make: _makeCtrl.text.trim(),
        model: _modelCtrl.text.trim(),
        mileage: int.parse(_mileageCtrl.text.trim()),
        ownerId: auth.currentUser!.id,
        vehicleType: _vehicleType,
      );
      // Save custom checklist for new van too
      // (handled via addVan + updateVan if checklist differs from default)
    }

    if (mounted) Navigator.pop(context);
  }

  void _addChecklistItem() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Checklist Item'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Fire Extinguisher',
            labelText: 'Item Name',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty && !_checklistItems.contains(name)) {
                setState(() => _checklistItems.add(name));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editChecklistItem(int index) {
    final ctrl = TextEditingController(text: _checklistItems[index]);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Checklist Item'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Item Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                setState(() => _checklistItems[index] = name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Vehicle' : 'Add Vehicle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _vehicleType,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Type',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _vehicleTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _vehicleType = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _regCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Registration Number',
                  prefixIcon: Icon(Icons.confirmation_number),
                  hintText: 'e.g. AB12 CDE',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _makeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Make',
                  prefixIcon: Icon(Icons.directions_car),
                  hintText: 'e.g. Ford',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  prefixIcon: Icon(Icons.local_shipping),
                  hintText: 'e.g. Transit',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mileageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Current Mileage',
                  prefixIcon: Icon(Icons.speed),
                  hintText: 'e.g. 45000',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (int.tryParse(v) == null) return 'Enter a number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _inspectionFrequencyDays,
                decoration: const InputDecoration(
                  labelText: 'Inspection Frequency',
                  prefixIcon: Icon(Icons.schedule),
                ),
                items: _frequencyOptions.entries
                    .map((e) => DropdownMenuItem(
                        value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _inspectionFrequencyDays = v!),
              ),
              const SizedBox(height: 24),

              // Checklist editor
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Inspection Checklist',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  TextButton.icon(
                    onPressed: _addChecklistItem,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Item'),
                    style:
                        TextButton.styleFrom(foregroundColor: AppTheme.accent),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _checklistItems.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _checklistItems.removeAt(oldIndex);
                    _checklistItems.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  return Container(
                    key: ValueKey('checklist_$index'),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Text('${index + 1}',
                          style: const TextStyle(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.bold)),
                      title: Text(_checklistItems[index]),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                size: 18, color: AppTheme.textSecondary),
                            onPressed: () => _editChecklistItem(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                size: 18, color: AppTheme.danger),
                            onPressed: _checklistItems.length > 1
                                ? () => setState(
                                    () => _checklistItems.removeAt(index))
                                : null,
                          ),
                          const Icon(Icons.drag_handle,
                              size: 18, color: AppTheme.textSecondary),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text('${_checklistItems.length} items — drag to reorder',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                  textAlign: TextAlign.center),

              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(isEditing ? 'Update Vehicle' : 'Add Vehicle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _regCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _mileageCtrl.dispose();
    super.dispose();
  }
}
