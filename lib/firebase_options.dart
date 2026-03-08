import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for Fleet Checker.
/// Replace these values with your own Firebase project config.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // TODO: Replace with actual Firebase project values
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'FIREBASE_API_KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'fleet-checker-demo',
    authDomain: 'fleet-checker-demo.firebaseapp.com',
    storageBucket: 'fleet-checker-demo.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'FIREBASE_API_KEY',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'fleet-checker-demo',
    storageBucket: 'fleet-checker-demo.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'FIREBASE_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'fleet-checker-demo',
    storageBucket: 'fleet-checker-demo.firebasestorage.app',
    iosBundleId: 'com.fleetchecker.fleetChecker',
  );
}
