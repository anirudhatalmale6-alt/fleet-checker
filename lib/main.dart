import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'services/data_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/firebase_data_service.dart';
import 'services/mock_auth_service.dart';
import 'services/mock_data_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/owner/owner_dashboard.dart';
import 'screens/driver/driver_dashboard.dart';

bool _useFirebase = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _useFirebase = true;
  } catch (_) {
    // Firebase not configured — use demo mode with mock services
    _useFirebase = false;
  }

  runApp(const FleetCheckerApp());
}

class FleetCheckerApp extends StatelessWidget {
  const FleetCheckerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => _useFirebase
              ? FirebaseAuthService()
              : MockAuthService(),
        ),
        Provider<DataService>(
          create: (_) => _useFirebase
              ? FirebaseDataService()
              : MockDataService(),
        ),
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

    if (!auth.initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    if (auth.currentUser!.role == UserRole.owner) {
      return const OwnerDashboard();
    }

    return const DriverDashboard();
  }
}
