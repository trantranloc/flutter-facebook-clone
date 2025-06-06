// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyArJ9vVF99QzQyAuR7dtojsMxP1bKfkVP4',
    appId: '1:883932268704:web:a7c628293312d60a6ca1c5',
    messagingSenderId: '883932268704',
    projectId: 'mobile-project-38915',
    authDomain: 'mobile-project-38915.firebaseapp.com',
    storageBucket: 'mobile-project-38915.firebasestorage.app',
    measurementId: 'G-9NWWEQN4W2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAmR1vKyq0ipUwxM5AsxjyNkEbsxHxyDfg',
    appId: '1:883932268704:android:1b62409c08b4535b6ca1c5',
    messagingSenderId: '883932268704',
    projectId: 'mobile-project-38915',
    storageBucket: 'mobile-project-38915.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCyCrBeSLaYYEkMYbNXWlacZ4tZ6o57J8I',
    appId: '1:883932268704:ios:c49b6d7c4ec6a39d6ca1c5',
    messagingSenderId: '883932268704',
    projectId: 'mobile-project-38915',
    storageBucket: 'mobile-project-38915.firebasestorage.app',
    iosBundleId: 'com.example.flutterFacebookClone',
  );

}