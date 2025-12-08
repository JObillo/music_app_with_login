import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:device_preview/device_preview.dart';

// Pages
import 'package:app_music/signup.dart';
import 'package:app_music/login.dart';
import 'package:app_music/navigation/home_page.dart';
import 'package:app_music/navigation/lyrics_page.dart';
import 'package:app_music/models/song.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(DevicePreview(builder: (context) => const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music App',
      debugShowCheckedModeBanner: false,
      builder: DevicePreview.appBuilder,
      initialRoute: '/login',

      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => const HomePage(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == '/lyrics') {
          final song = settings.arguments as Song;
          return MaterialPageRoute(
            builder: (context) => LyricsPage(song: song),
          );
        }
        return null;
      },

      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1877F2),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1877F2),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF1877F2)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1F1F1F),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white38),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF1877F2)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.grey[900],
          contentTextStyle: const TextStyle(color: Colors.white),
          actionTextColor: const Color(0xFF1877F2),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF1877F2), // Facebook blue cursor
          selectionColor: Color(0xFF1877F2), // Text selection highlight
          selectionHandleColor: Color(0xFF1877F2), // Handle color
        ),
      ),
    );
  }
}
