import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/app_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'screens/permissions_setup_screen.dart';
import 'theme/theme.dart';
import 'services/background_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> _cacheAlarmAudio() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/alarm.mp3');
    
    // Copy from assets if missing OR if file is corrupt (zero bytes)
    bool needsCopy = !await file.exists();
    if (!needsCopy) {
      final fileSize = await file.length();
      if (fileSize == 0) {
        debugPrint('AUDIO_CACHE: File exists but is empty/corrupt, re-copying');
        needsCopy = true;
      }
    }

    if (needsCopy) {
      debugPrint('AUDIO_CACHE: Copying from rootBundle to ${file.path}');
      final byteData = await rootBundle.load('assets/sounds/alarm.mp3');
      await file.writeAsBytes(byteData.buffer.asUint8List());
    } else {
      debugPrint('AUDIO_CACHE: File already exists at ${file.path}');
    }

    await prefs.setString('cached_alarm_path', file.path);
    debugPrint('AUDIO_CACHE: Successfully saved to SharedPreferences -> ${file.path}');
  } catch (e) {
    debugPrint('Failed to cache alarm audio: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  GoogleFonts.config.allowRuntimeFetching = false;

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: Local .env file could not be loaded: $e");
  }

  // Cache alarm audio and initialize service asynchronously without blocking runApp
  _cacheAlarmAudio().then((_) {
    initializeBackgroundService();
  });

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Enable offline persistence for critical safety features
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF121212),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ProtegaApp());
}

class ProtegaApp extends StatelessWidget {
  const ProtegaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            title: 'Protega',
            debugShowCheckedModeBanner: false,
            themeMode: provider.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const AppRoot(),
          );
        },
      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _setupComplete = true; // assume true until we check

  @override
  void initState() {
    super.initState();
    _checkSetupStatus();
  }

  Future<void> _checkSetupStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('permissions_setup_done') ?? false;
    if (mounted) {
      setState(() => _setupComplete = done);
    }
  }

  Future<void> _markSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_setup_done', true);

    // Now that permissions are granted, start the background service
    _cacheAlarmAudio().then((_) {
      initializeBackgroundService();
    });

    if (mounted) {
      setState(() => _setupComplete = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // While waiting for initial Firebase auth state, show a clean loading splash
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            ),
          );
        }

        // 1. Explicitly not logged in → show AuthScreen
        if (snapshot.data == null) {
          return const AuthScreen();
        }

        // Logged in: Wait for provider to load profile data
        return Consumer<AppProvider>(
          builder: (context, provider, _) {
            if (provider.currentUser == null) {
              return Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                body: const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent),
                ),
              );
            }

            // 2. First-time setup check
            if (!_setupComplete) {
              return PermissionsSetupScreen(
                onComplete: _markSetupDone,
              );
            }

            // 3. All good → show app dashboard
            return const HomeShell();
          },
        );
      },
    );
  }
}
