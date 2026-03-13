import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/van_model.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_theme.dart';
import 'add_van_screen.dart';
import 'subscription_screen.dart';

class VanListScreen extends StatelessWidget {
  const VanListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final data = context.read<DataService>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Vehicles')),
      floatingActionButton: StreamBuilder<List<Van>>(
        stream: data.watchVansForOwner(auth.currentUser!.id),
        builder: (context, vanSnap) {
          final vans = vanSnap.data ?? [];
          final sub = context.watch<SubscriptionService>();

          return FloatingActionButton.extended(
            onPressed: () => _handleAddVan(context, sub, vans.length),
            icon: const Icon(Icons.add),
            label: const Text('Add Vehicle'),
          );
        },
      ),
      body: StreamBuilder<List<Van>>(
        stream: data.watchVansForOwner(auth.currentUser!.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final vans = snapshot.data ?? [];
          if (vans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined,
                      size: 64,
                      color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('No vehicles yet',
                      style: TextStyle(
                          fontSize: 18, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  const Text('Tap + to add your first vehicle',
                      style: TextStyle(
                          fontSize: 14, color: AppTheme.textSecondary)),
                ],
              ),
            );
          }
          return ListView.builder(
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(van.vehicleType,
                                style: const TextStyle(
                                    fontSize: 11, color: AppTheme.accent)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
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
                          ),
                        ],
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
                            title: const Text('Delete Vehicle?'),
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
          );
        },
      ),
    );
  }

  void _handleAddVan(
      BuildContext context, SubscriptionService sub, int currentVans) {
    // Not subscribed at all — go to subscription page
    if (!sub.ownerSubscribed) {
      _showSubscriptionDialog(
        context,
        'You need an active Owner subscription to add vehicles.',
      );
      return;
    }

    // No van subscription yet — go to subscription page
    if (!sub.vanSubscribed) {
      _showSubscriptionDialog(
        context,
        'You need a Van subscription to add vehicles. It\'s just £0.99 per van per week.',
      );
      return;
    }

    // Has room in current tier — add directly
    if (currentVans < sub.vanLimit) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AddVanScreen()));
      return;
    }

    // Needs upgrade — show upgrade dialog
    final nextTier = sub.nextTierForAddingVan(currentVans);
    if (nextTier == null) {
      _showSubscriptionDialog(
        context,
        'You\'ve reached the maximum van limit. Please contact support for larger fleets.',
      );
      return;
    }

    final newWeeklyCost = (nextTier * 0.99).toStringAsFixed(2);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Upgrade Van Plan'),
        content: Text(
          'Adding another van will upgrade your weekly plan from '
          '${sub.vanLimit} van${sub.vanLimit == 1 ? '' : 's'} to $nextTier van${nextTier == 1 ? '' : 's'} '
          '(£$newWeeklyCost/week).\n\n'
          'That\'s £0.99 per van per week.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await sub.purchaseVanTier(nextTier);
              if (success && context.mounted) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddVanScreen()));
              }
            },
            child: const Text('Upgrade & Add Van'),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Subscription Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SubscriptionScreen()));
            },
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
  }
}
