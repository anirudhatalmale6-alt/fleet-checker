import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/web_notification_helper.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _pushEnabled;
  late bool _emailEnabled;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser!;
    _pushEnabled = user.notifyPush;
    _emailEnabled = user.notifyEmail;
  }

  Future<void> _togglePush(bool value) async {
    if (value && WebNotificationHelper.permission != 'granted') {
      final granted = await WebNotificationHelper.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Notification permission denied. Please allow notifications in your browser settings.'),
            ),
          );
        }
        return;
      }
    }

    setState(() => _pushEnabled = value);
    await _save({'notifyPush': value});
  }

  Future<void> _toggleEmail(bool value) async {
    setState(() => _emailEnabled = value);
    await _save({'notifyEmail': value});
  }

  Future<void> _save(Map<String, dynamic> data) async {
    setState(() => _saving = true);
    await context.read<AuthService>().updateProfile(data);
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose how you want to be notified when drivers submit inspections.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                _SettingsTile(
                  icon: Icons.notifications_active,
                  iconColor: AppTheme.accent,
                  title: 'Push Notifications',
                  subtitle:
                      'Get browser alerts when inspections are submitted',
                  trailing: Switch(
                    value: _pushEnabled,
                    onChanged: _togglePush,
                    activeColor: AppTheme.accent,
                  ),
                ),
                const SizedBox(height: 12),
                _SettingsTile(
                  icon: Icons.email_outlined,
                  iconColor: AppTheme.accentLight,
                  title: 'Email Notifications',
                  subtitle: 'Receive email summaries of inspection activity',
                  trailing: Switch(
                    value: _emailEnabled,
                    onChanged: _toggleEmail,
                    activeColor: AppTheme.accent,
                  ),
                ),
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                const Text(
                  'About',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsTile(
                  icon: Icons.info_outline,
                  iconColor: AppTheme.textSecondary,
                  title: 'Fleet Checker',
                  subtitle: 'Version 1.0.0',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
