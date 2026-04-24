import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'providers/quest_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/notification_service.dart';

// Global key so NotificationService can show snackbars
// from outside the widget tree (foreground FCM messages).
final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => QuestProvider()),
      ],
      child: const ARQuestApp(),
    ),
  );
}

class ARQuestApp extends StatelessWidget {
  const ARQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARQuest',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE86A1F)),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Track which uid we last initialized FCM for so we
  // don't call initialize() on every rebuild.
  String? _initializedForUid;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user != null) {
      // Only initialize FCM once per user session, not on every rebuild.
      if (_initializedForUid != user.uid) {
        _initializedForUid = user.uid;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationService().initialize(
            userId: user.uid,
            messengerKey: messengerKey,
          );
        });
      }
      return const HomeScreen();
    }

    // Reset so FCM re-initializes if a different user signs in.
    _initializedForUid = null;
    return const LoginScreen();
  }
}