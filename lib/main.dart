
import 'package:cgas_admin/onboarding/dashboard.dart';
import 'package:cgas_admin/onboarding/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options:const FirebaseOptions(
    apiKey: 'AIzaSyDiPdMqr41xcHRuCzdPI25FD62YJM0gqVU',
    appId: '1:687178952062:web:606a8cf5a9209a45a4d72f',
    messagingSenderId: '687178952062',
    projectId: 'cgas-2024',
    authDomain: 'cgas-2024.firebaseapp.com',
    storageBucket: 'cgas-2024.appspot.com',
    measurementId: 'G-9LQ0M9XDWL',
  ));
  runApp(const MainApp());
}
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AdminDashboard(),
      // home: LoginPage()
    );
  }
}
