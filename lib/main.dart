import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';


import 'screens/auth_gate.dart';
import 'screens/home.dart';
import 'screens/questions.dart';
import 'screens/suggestion.dart';
import 'screens/history.dart';
import 'screens/setting.dart';
import 'screens/profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meal Suggestion App',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      routes: {
        '/auth': (context) => AuthGate(),
        '/home': (context) => HomeScreen(),
        '/questions': (context) => QuestionsScreen(),
        '/suggestion': (context) => SuggestionScreen(),
        '/history': (context) => HistoryScreen(),
        '/settings': (context) => SettingsScreen(), // Added
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}

// SPLASH SCREEN
class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(image: AssetImage("assets/background.jpg"),
          fit: BoxFit.cover),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [



              SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/auth');
                },
                child: Text('Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



// Text(
// 'Meal App Logo',
// style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
// ),