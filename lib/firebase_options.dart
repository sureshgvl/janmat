import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDst-RA1ennLcjLf2dHABau2GFLR2W2IM0',
    appId: '1:231534632940:android:8ddfbeecf27fd562acca29',
    messagingSenderId: '231534632940',
    projectId: 'janmat-8e831',
    storageBucket: 'janmat-8e831.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDst-RA1ennLcjLf2dHABau2GFLR2W2IM0',
    appId: '1:231534632940:web:bdb07b3ca9d1ffcd57aac9',
    messagingSenderId: '231534632940',
    projectId: 'janmat-8e831',
    storageBucket: 'janmat-8e831.firebasestorage.app',
    authDomain: 'janmat-8e831.firebaseapp.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA4l1UprD8EvEgA5OpFhcfPF5UidE-bH1w',
    appId: '1:231534632940:ios:034314ab6b31ef4557aac9',
    messagingSenderId: '231534632940',
    projectId: 'janmat-8e831',
    storageBucket: 'janmat-8e831.firebasestorage.app',
    androidClientId: '231534632940-p736cr1r1rkp7in97p9ok75tjd0ql4sn.apps.googleusercontent.com',
    iosClientId: '231534632940-qni645u93bauc3ecnkvpm5jk6c5rs8td.apps.googleusercontent.com',
    iosBundleId: 'com.sg.janmat',
  );
}
