import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCwdSsMXtUDZJ2ANb_xF3LzQzu8gdYr7Gk',
    appId: '1:22991003242:android:7aca4b8b493f1281d3f413',
    messagingSenderId: '22991003242',
    projectId: 'findju-165e0',
    storageBucket: 'findju-165e0.firebasestorage.app',
  );
}
