// Replace placeholders by running on your PC (requires Flutter + Firebase login):
//   .\scripts\configure_firebase.ps1 YOUR_FIREBASE_PROJECT_ID
// Or: `dart pub global activate flutterfire_cli` then `flutterfire configure`.

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
      case TargetPlatform.macOS:
        return macos;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDz_iRFn7Z9-X076W4ELwVOSZ46-gUmoh8',
    appId: '1:296817831055:web:4211267ee7a483fc92d4fa',
    messagingSenderId: '296817831055',
    projectId: 'tuition-attendance-9a2b1',
    authDomain: 'tuition-attendance-9a2b1.firebaseapp.com',
    storageBucket: 'tuition-attendance-9a2b1.firebasestorage.app',
    measurementId: 'G-J853YCGDW5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAmoMPk51elYGPyuBSROK5x5BkUA9sioPc',
    appId: '1:296817831055:android:26dcfece4c8d97d192d4fa',
    messagingSenderId: '296817831055',
    projectId: 'tuition-attendance-9a2b1',
    storageBucket: 'tuition-attendance-9a2b1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.tuitionAttendanceManager',
  );

  static const FirebaseOptions macos = ios;
}
