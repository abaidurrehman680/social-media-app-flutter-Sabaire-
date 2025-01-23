import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // Alias for Firebase User
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:social/components/life_cycle_event_handler.dart';
import 'package:social/landing/landing_page.dart';
import 'package:social/screens/mainscreen.dart';
import 'package:social/services/user_service.dart';
import 'package:social/utils/config.dart';
import 'package:social/utils/constants.dart';
import 'package:social/utils/providers.dart';
import 'package:social/view_models/theme/theme_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase; // Alias for Supabase User

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Config.initFirebase();

  // Initialize Supabase
  await supabase.Supabase.initialize(
    url: 'https://necojgradneivznuosxf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5lY29qZ3JhZG5laXZ6bnVvc3hmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzY2MjE1MTYsImV4cCI6MjA1MjE5NzUxNn0.kc-3ALQUyNtJNPuRlZa68MRxz_wxTB7QFhxZTbrCazk',
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Adding lifecycle event observer for app state changes
    WidgetsBinding.instance.addObserver(
      LifecycleEventHandler(
        detachedCallBack: () => UserService().setUserStatus(false),
        resumeCallBack: () => UserService().setUserStatus(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: Consumer<ThemeProvider>(
        builder: (context, ThemeProvider notifier, Widget? child) {
          return MaterialApp(
            title: Constants.appName,
            debugShowCheckedModeBanner: false,
            theme: _themeData(
              notifier.dark ? Constants.darkTheme : Constants.lightTheme,
            ),
            home: StreamBuilder<firebase_auth.User?>(
              stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // You can show a loading indicator here
                  return CircularProgressIndicator();
                }

                if (snapshot.hasData) {
                  return TabScreen(); // Authenticated user
                } else {
                  return Landing(); // Unauthenticated user
                }
              },
            ),
          );
        },
      ),
    );
  }

  // Method to apply custom theme using Google Fonts
  ThemeData _themeData(ThemeData theme) {
    return theme.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(
        theme.textTheme,
      ),
    );
  }
}
