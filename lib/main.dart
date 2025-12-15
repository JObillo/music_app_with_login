import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:device_preview/device_preview.dart';

// Pages
import 'login.dart';
import 'signup.dart';
import 'navigation/lyrics_page.dart';
import 'models/song.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Belle Music',
      debugShowCheckedModeBanner: false,
      builder: DevicePreview.appBuilder,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/lyrics') {
          final song = settings.arguments as Song;
          return MaterialPageRoute(builder: (_) => LyricsPage(song: song));
        }
        return null;
      },
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFB76E79),
        scaffoldBackgroundColor: const Color(0xFFF7F3F2),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFB76E79),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB76E79),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFB76E79)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: Color(0xFF8B5E5B)),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF8B5E5B)),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFB76E79)),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
