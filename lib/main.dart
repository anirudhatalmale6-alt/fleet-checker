import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'services/data_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/owner/owner_dashboard.dart';
import 'screens/driver/driver_dashboard.dart';

void main() {
  runApp(const FleetCheckerApp());
}

class FleetCheckerApp extends StatelessWidget {
  const FleetCheckerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => DataService()),
      ],
      child: MaterialApp(
        title: 'Fleet Checker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    if (auth.currentUser!.role == UserRole.owner) {
      return const OwnerDashboard();
    }

    return const DriverDashboard();
  }
}
