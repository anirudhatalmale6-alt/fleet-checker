import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/van_model.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';

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

  bool get isEditing => widget.van != null;

  @override
  void initState() {
    super.initState();
    _regCtrl = TextEditingController(text: widget.van?.registration ?? '');
    _makeCtrl = TextEditingController(text: widget.van?.make ?? '');
    _modelCtrl = TextEditingController(text: widget.van?.model ?? '');
    _mileageCtrl =
        TextEditingController(text: widget.van?.mileage.toString() ?? '');
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final data = context.read<DataService>();
    final auth = context.read<AuthService>();

    if (isEditing) {
      final van = widget.van!;
      van.registration = _regCtrl.text.trim().toUpperCase();
      van.make = _makeCtrl.text.trim();
      van.model = _modelCtrl.text.trim();
      van.mileage = int.parse(_mileageCtrl.text.trim());
      data.updateVan(van);
    } else {
      data.addVan(
        registration: _regCtrl.text.trim(),
        make: _makeCtrl.text.trim(),
        model: _modelCtrl.text.trim(),
        mileage: int.parse(_mileageCtrl.text.trim()),
        ownerId: auth.currentUser!.id,
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Van' : 'Add Van')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(isEditing ? 'Update Van' : 'Add Van'),
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
