import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_theme.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: sub.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Free trial banner
                      if (!sub.ownerSubscribed && sub.activeVanPlan == null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.accent.withValues(alpha: 0.2),
                                AppTheme.accentLight.withValues(alpha: 0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.accent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.celebration, color: AppTheme.accent, size: 28),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '2 Weeks Free Trial!',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Try Fleet Checker free for 14 days. Cancel anytime.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Current status
                      _StatusBanner(sub: sub),
                      const SizedBox(height: 28),

                      // Owner plan
                      const Text(
                        'Owner Plan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _OwnerPlanCard(sub: sub),
                      const SizedBox(height: 28),

                      // Van plans
                      const Text(
                        'Van Plans',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Choose how many vans you need',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...sub.vanProducts.map((product) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _VanPlanCard(
                              product: product,
                              isActive:
                                  sub.activeVanPlan == product.id,
                              sub: sub,
                            ),
                          )),

                      const SizedBox(height: 20),

                      // Restore purchases
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            await sub.restorePurchases();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Purchases restored')),
                              );
                            }
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Restore Purchases'),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final SubscriptionService sub;
  const _StatusBanner({required this.sub});

  @override
  Widget build(BuildContext context) {
    final hasOwner = sub.ownerSubscribed;
    final hasVans = sub.activeVanPlan != null;

    if (!hasOwner && !hasVans) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.warning),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No active subscription. Subscribe to start managing your fleet.',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.success),
              const SizedBox(width: 12),
              Text(
                hasOwner ? 'Active Subscription' : 'Partial Subscription',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          if (hasVans) ...[
            const SizedBox(height: 8),
            Text(
              'Van limit: ${sub.vanLimit} vans',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _OwnerPlanCard extends StatelessWidget {
  final SubscriptionService sub;
  const _OwnerPlanCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final product = sub.ownerProduct;
    final isActive = sub.ownerSubscribed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.success.withValues(alpha: 0.1)
            : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? AppTheme.success.withValues(alpha: 0.4)
              : AppTheme.surface,
          width: isActive ? 2 : 1,
        ),
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
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: AppTheme.accent, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Owner Access',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      product != null ? '${product.price}/month' : '£3.99/month',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.accentLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const _FeatureRow(text: 'Full fleet management dashboard'),
          const _FeatureRow(text: 'Add and manage drivers'),
          const _FeatureRow(text: 'View all inspection reports'),
          const _FeatureRow(text: 'PDF report generation'),
          const _FeatureRow(text: 'Push notifications for inspections'),
          if (!isActive) ...[
            const SizedBox(height: 12),
            const _FeatureRow(text: '2-week free trial included'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: product == null
                    ? null
                    : () => _purchase(context, sub),
                child: const Text('Start Free Trial'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _purchase(BuildContext context, SubscriptionService sub) async {
    final success = await sub.purchaseOwnerSubscription();
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase could not be completed')),
      );
    }
  }
}

class _VanPlanCard extends StatelessWidget {
  final dynamic product; // ProductDetails
  final bool isActive;
  final SubscriptionService sub;

  const _VanPlanCard({
    required this.product,
    required this.isActive,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final vanCount = SubscriptionService.vanLimits[product.id] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.accent.withValues(alpha: 0.1)
            : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? AppTheme.accent.withValues(alpha: 0.5)
              : AppTheme.surface,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$vanCount',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$vanCount Vans',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${product.price}/week',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.accentLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isActive)
                  const Text(
                    '2 weeks free',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (isActive)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'CURRENT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: () => _purchase(context),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Select'),
            ),
        ],
      ),
    );
  }

  Future<void> _purchase(BuildContext context) async {
    final success = await sub.purchaseVanPlan(product.id);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase could not be completed')),
      );
    }
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  const _FeatureRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check, color: AppTheme.success, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
