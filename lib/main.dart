import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/profile_completion_screen.dart';
import 'screens/candidate/candidate_profile_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/main_tab_navigation.dart';
import 'core/app_bindings.dart';
import 'l10n/app_localizations.dart';

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
    return FutureBuilder<String>(
      future: _getInitialRoute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final initialRoute = snapshot.data ?? '/login';

        return GetMaterialApp(
          title: 'JanMat',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          initialBinding: AppBindings(),
          initialRoute: initialRoute,
          getPages: [
            GetPage(name: '/login', page: () => const LoginScreen()),
            GetPage(name: '/home', page: () => const MainTabNavigation()),
            GetPage(name: '/profile', page: () => const ProfileScreen()),
            GetPage(name: '/profile-completion', page: () => const ProfileCompletionScreen()),
            GetPage(name: '/candidate-profile', page: () => const CandidateProfileScreen()),
            GetPage(name: '/chat', page: () => const ChatListScreen()),
            GetPage(name: '/settings', page: () => const SettingsScreen()),
          ],
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }

  Future<String> _getInitialRoute() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return '/login';
    }

    try {
      // Check if user profile is complete
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final profileCompleted = userData?['profileCompleted'] ?? false;

        if (!profileCompleted) {
          return '/profile-completion';
        }
      } else {
        // User document doesn't exist, need profile completion
        return '/profile-completion';
      }

      return '/home';
    } catch (e) {
      // If there's an error checking profile, default to login
      return '/login';
    }
  }
}
