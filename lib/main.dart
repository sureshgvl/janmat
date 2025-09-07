import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'core/app_bindings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user is already logged in
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String initialRoute = currentUser != null ? '/home' : '/login';

    return GetMaterialApp(
      title: 'JanMat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialBinding: AppBindings(),
      initialRoute: initialRoute,
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/profile', page: () => const ProfileScreen()),
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}
