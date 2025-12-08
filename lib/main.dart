import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:device_preview/device_preview.dart';

// Your pages
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
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/home': (context) => HomePage(),
      },

      // Lyrics page uses arguments, so use onGenerateRoute
      onGenerateRoute: (settings) {
        if (settings.name == '/lyrics') {
          final song = settings.arguments as Song;
          return MaterialPageRoute(
            builder: (context) => LyricsPage(song: song),
          );
        }
        return null;
      },
    );
  }
}
