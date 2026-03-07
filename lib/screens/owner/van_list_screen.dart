import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../theme/app_theme.dart';
import 'add_van_screen.dart';

class VanListScreen extends StatelessWidget {
  const VanListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final data = context.watch<DataService>();
    final vans = data.getVansForOwner(auth.currentUser!.id);

    return Scaffold(
      appBar: AppBar(title: const Text('My Vans')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AddVanScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Add Van'),
      ),
      body: vans.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined,
                      size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('No vans yet',
                      style:
                          TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  const Text('Tap + to add your first van',
                      style:
                          TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vans.length,
              itemBuilder: (context, index) {
                final van = vans[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_shipping,
                          color: AppTheme.accent),
                    ),
                    title: Text(van.registration,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('${van.make} ${van.model}'),
                        const SizedBox(height: 2),
                        Text(
                          van.assignedDriverName != null
                              ? 'Driver: ${van.assignedDriverName}'
                              : 'No driver assigned',
                          style: TextStyle(
                            color: van.assignedDriverName != null
                                ? AppTheme.success
                                : AppTheme.warning,
                            fontSize: 13,
                          ),
                        ),
                        Text('Mileage: ${van.mileage}',
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete',
                                style: TextStyle(color: AppTheme.danger))),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => AddVanScreen(van: van)));
                        } else if (value == 'delete') {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Van?'),
                              content: Text(
                                  'Remove ${van.registration} from your fleet?'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    data.deleteVan(van.id);
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('Delete',
                                      style:
                                          TextStyle(color: AppTheme.danger)),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
