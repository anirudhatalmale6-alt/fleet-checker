import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBSaxiEZiyCZcgDTYo2KuD_G9T5DIkHyiQ',
    appId: '1:747477788438:web:f49d8e8c854cfd774a1237',
    messagingSenderId: '747477788438',
    projectId: 'vehicle-checker-7956a',
    authDomain: 'vehicle-checker-7956a.firebaseapp.com',
    storageBucket: 'vehicle-checker-7956a.firebasestorage.app',
    measurementId: 'G-0WDYKL9GKP',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBxO-8mf_PFLaBiH-zGTDrHs6HJM1y8Eo',
    appId: '1:747477788438:android:2fc9ac8802b0a034a1237',
    messagingSenderId: '747477788438',
    projectId: 'vehicle-checker-7956a',
    storageBucket: 'vehicle-checker-7956a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDer51drbdsSKhuPhIPt02yturrt3n_KE',
    appId: '1:747477788438:ios:3503a2662ead07094a1237',
    messagingSenderId: '747477788438',
    projectId: 'vehicle-checker-7956a',
    storageBucket: 'vehicle-checker-7956a.firebasestorage.app',
    iosBundleId: 'com.fleetchecker.fleetChecker',
  );
}
