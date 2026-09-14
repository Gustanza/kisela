import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/update_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const KiselaApp());
  // Fire-and-forget, deliberately not awaited: this shows a native
  // permission dialog, and awaiting it here (before runApp) used to hang
  // the whole app on Android's launch icon forever on devices where that
  // dialog doesn't resolve cleanly before the first Flutter frame attaches.
  unawaited(NotificationService.instance.initialize());
}

class KiselaApp extends StatelessWidget {
  const KiselaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kisela',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _UpdateGate(child: AuthGate()),
    );
  }
}

/// Checks the Play Store for updates on launch and whenever the app comes
/// back to the foreground. A release marked high-priority in Play Console
/// forces a blocking update via Play's own UI; anything else gets a quiet
/// "restart to update" banner the user can dismiss and act on later.
class _UpdateGate extends StatefulWidget {
  final Widget child;

  const _UpdateGate({required this.child});

  @override
  State<_UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<_UpdateGate> with WidgetsBindingObserver {
  bool _optionalPromptShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForUpdate();
    }
  }

  Future<void> _checkForUpdate() async {
    final result = await UpdateService.checkForUpdate();
    if (!mounted) return;

    switch (result.action) {
      case UpdateAction.forced:
        await UpdateService.performImmediateUpdate();
        break;
      case UpdateAction.optional:
        if (!_optionalPromptShown) {
          _optionalPromptShown = true;
          _startFlexibleUpdate();
        }
        break;
      case UpdateAction.none:
        break;
    }
  }

  Future<void> _startFlexibleUpdate() async {
    final downloaded = await UpdateService.startFlexibleUpdate();
    if (!mounted || !downloaded) return;

    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: const Text('An update has been downloaded.'),
        actions: [
          TextButton(
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: UpdateService.completeFlexibleUpdate,
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }
        final user = authSnapshot.data;
        if (user == null) {
          return const AuthScreen();
        }
        return _ProfileGate(uid: user.uid);
      },
    );
  }
}

class _ProfileGate extends StatefulWidget {
  final String uid;

  const _ProfileGate({required this.uid});

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _firestoreService.profileStream(widget.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }
        final profile = snapshot.data;
        if (profile == null) {
          return const OnboardingScreen();
        }
        return HomeScreen(myProfile: profile);
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
