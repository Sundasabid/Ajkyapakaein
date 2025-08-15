import 'dart:async';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

// Screens
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
        fontFamily: 'Serif',
      ),
      debugShowCheckedModeBanner: false,
      home: GetStartedScreen(),
      routes: {
        '/auth': (context) => AuthGate(),
        '/home': (context) => HomeScreen(),
        '/questions': (context) => QuestionsScreen(),
        '/suggestion': (context) => SuggestionScreen(),
        '/history': (context) => HistoryScreen(),
        '/settings': (context) => SettingsScreen(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}

// ---------------- SPLASH SCREEN ----------------
class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          //image: DecorationImage(image: AssetImage("assets/background.jpg"), fit: BoxFit.cover,),

          gradient: LinearGradient(
            colors: [Color(0xFFFFF5E1), Color(0xFFFFEFD1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: MediaQuery.of(context).size.height * 0.25,
              right: MediaQuery.of(context).size.width * 0.25,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6AE2D).withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.25,
              left: MediaQuery.of(context).size.width * 0.33,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFE94F37).withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Main content
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),

                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                      image: const DecorationImage(
                        image: NetworkImage(
                          "https://uploadthingy.s3.us-west-1.amazonaws.com/hcFrRBDuLq3kSNzxKBMRw8/icon.jpg",
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  const Text(
                    "Aaj Kya Pakayen?",
                    style: TextStyle(
                      fontFamily: "serif",
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE94F37),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)
                          ),
                          child: Stack(
                            children: [
                              Image.network(
                                "https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?auto=format&fit=crop&w=780&q=80",
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                bottom: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF6AE2D),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    "Featured Recipe",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Discover Delicious Recipes",
                                style: TextStyle(
                                  fontFamily: "serif",
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "Never wonder what to cook again! Find recipes based on what's in your kitchen, your preferences, and your mood.",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Features
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: const [
                                  FeatureChip(text: "Personalized suggestions", color: Color(0xFFE94F37)),
                                  FeatureChip(text: "Quick & easy recipes", color: Color(0xFFF6AE2D)),
                                  FeatureChip(text: "Ingredient search instantly", color: Color(0xFFE94F37)),
                                  FeatureChip(text: "Save favorites", color: Color(0xFFF6AE2D)),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE94F37),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => AuthGate()),
                                    );
                                  },
                                  label: const Text(
                                    "Get Started",
                                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  //icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),

                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "© 2025 Aaj Kya Pakayen? | All recipes curated with ♥",
                    style: TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeatureChip extends StatelessWidget {
  final String text;
  final Color color;
  const FeatureChip({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }
}