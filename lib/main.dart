import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login.dart';
import 'screens/signup.dart';
import 'screens/homepage.dart';
import 'screens/verification_screen.dart';
import 'screens/reset_password.dart';
import 'screens/post_item_form.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/all_items_screen.dart';
import 'screens/item_detail_screen.dart';
import 'screens/my_items_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/chat_screen.dart';

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
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'FindJU',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomeScreen(),
          '/verify': (context) => const VerificationScreen(),
          '/forgot-password': (context) => const ResetPasswordScreen(),
          '/report-lost': (context) => const PostItemScreen(type: 'Lost'),
          '/report-found': (context) => const PostItemScreen(type: 'Found'),
          '/profile': (context) => const ProfileScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/all-items': (context) => const AllItemsScreen(),
          '/item-detail': (context) => const ItemDetailScreen(),
          '/my-items': (context) => const MyItemsScreen(),
          '/messages': (context) => const MessagesScreen(),
          '/chat': (context) => const ChatScreen(),
        },
      ),
    );
  }
}