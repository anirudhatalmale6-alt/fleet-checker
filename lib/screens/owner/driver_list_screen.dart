import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/van_model.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../theme/app_theme.dart';

class DriverListScreen extends StatelessWidget {
  const DriverListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final data = context.read<DataService>();
    final ownerId = auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Drivers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDriverDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Driver'),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: auth.watchDriversForOwner(ownerId),
        builder: (context, driverSnap) {
          return StreamBuilder<List<Van>>(
            stream: data.watchVansForOwner(ownerId),
            builder: (context, vanSnap) {
              if (driverSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final drivers = driverSnap.data ?? [];
              final vans = vanSnap.data ?? [];

              if (drivers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64,
                          color: AppTheme.textSecondary
                              .withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text('No drivers yet',
                          style: TextStyle(
                              fontSize: 18,
                              color: AppTheme.textSecondary)),
                      const SizedBox(height: 8),
                      const Text(
                          'Tap + to add a driver',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...drivers.map((driver) {
                    final assignedVan = vans
                        .where(
                            (v) => v.assignedDriverId == driver.id)
                        .toList();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              AppTheme.accent.withValues(alpha: 0.15),
                          child: Text(
                            driver.name[0].toUpperCase(),
                            style: const TextStyle(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                        ),
                        title: Text(driver.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(driver.email,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              assignedVan.isNotEmpty
                                  ? 'Assigned: ${assignedVan.map((v) => v.registration).join(", ")}'
                                  : 'No van assigned',
                              style: TextStyle(
                                fontSize: 13,
                                color: assignedVan.isNotEmpty
                                    ? AppTheme.success
                                    : AppTheme.warning,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                              Icons.local_shipping_outlined),
                          tooltip: 'Assign Van',
                          onPressed: () => _showAssignVanDialog(
                              context, driver, vans, data),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showAddDriverDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Driver'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create a login for your driver. They can use these credentials to sign in and submit inspections.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Driver Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password (min 6 chars)',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                if (errorMsg != null) ...[
                  const SizedBox(height: 12),
                  Text(errorMsg!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || passwordCtrl.text.length < 6) {
                  setDialogState(() {
                    errorMsg = 'Please fill in all fields (password min 6 characters)';
                  });
                  return;
                }
                final auth = ctx.read<AuthService>();
                final err = await auth.addDriver(
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  password: passwordCtrl.text,
                  ownerId: auth.currentUser!.id,
                );
                if (err != null) {
                  setDialogState(() {
                    errorMsg = err;
                  });
                  return;
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add Driver'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignVanDialog(BuildContext context, AppUser driver,
      List<Van> vans, DataService data) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Assign van to ${driver.name}'),
        children: [
          ...vans.map((van) => SimpleDialogOption(
                onPressed: () {
                  data.assignDriver(van.id, driver.id, driver.name);
                  Navigator.pop(ctx);
                },
                child:
                    Text('${van.registration} - ${van.make} ${van.model}'),
              )),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}
