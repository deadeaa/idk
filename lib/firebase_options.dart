import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyBfmi1hLh57BldyF9Tcv3J2Wc9yuCf7FzM",
    authDomain: "nara-skincare.firebaseapp.com",
    projectId: "nara-skincare",
    storageBucket: "nara-skincare.firebasestorage.app",
    messagingSenderId: "233191954348",
    appId: "1:233191954348:web:3d1074db6eeac3b1e14c09",
  );
}
