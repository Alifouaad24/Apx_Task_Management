// ignore_for_file: type=lint
//
// PLACEHOLDER — replace this file with the one generated for your project:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// The generated file has the same name and shape, so nothing else in the app
// needs to change. Until then [DefaultFirebaseOptions.hasValidConfiguration]
// reports `false`, `main()` skips `Firebase.initializeApp`, and the app runs
// normally with push notifications and analytics disabled.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Firebase configuration per platform.
class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  /// Sentinel used by the placeholder values below.
  static const String _placeholder = 'REPLACE_ME';

  /// `false` while the placeholders are still in place.
  ///
  /// `main()` checks this before calling `Firebase.initializeApp`, so a fresh
  /// clone of this repo builds and runs without any Firebase setup at all.
  static bool get hasValidConfiguration =>
      !currentPlatform.apiKey.contains(_placeholder);

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return web;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDlD4f1MpiEB22Mk0kZ4Se6WSs3v58Ehwk',
    appId: '1:199740475189:android:2fe7b320d549087a0eee7c',
    messagingSenderId: '199740475189',
    projectId: 'apx-task-management',
    storageBucket: 'apx-task-management.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDimpHdZf9y_b-1r2JjaNmxyp9HqksGQb0',
    appId: '1:199740475189:ios:71397a924e83a9290eee7c',
    messagingSenderId: '199740475189',
    projectId: 'apx-task-management',
    storageBucket: 'apx-task-management.firebasestorage.app',
    iosBundleId: 'com.example.apxTaskManagement',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: '${_placeholder}_MACOS_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'apx-task-management',
    storageBucket: 'apx-task-management.appspot.com',
    iosBundleId: 'com.example.apxTaskManagement',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '${_placeholder}_WEB_API_KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'apx-task-management',
    authDomain: 'apx-task-management.firebaseapp.com',
    storageBucket: 'apx-task-management.appspot.com',
  );
}