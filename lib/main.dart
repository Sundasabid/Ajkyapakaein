import 'dart:async';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'recipe_data.dart';


import 'model/settings_model.dart';
import 'model/user_profile.dart';

// screens
import 'screens/auth_gate.dart';
import 'screens/home.dart';
import 'screens/questions1.dart';
import 'screens/question2.dart';
import 'screens/questions3.dart';
import 'screens/questions4.dart';
import 'screens/questions5.dart';
import 'screens/suggestion.dart';
import 'screens/history.dart';
import 'screens/setting.dart';
import 'screens/profile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProfile()),
        ChangeNotifierProvider(create: (_) => SettingsModel()),
      ],
      child: const MyApp(),
    ),
  );
}


// ----------------- Data Models -----------------

class Recipe {
  final String id;
  final String name;
  final String type;
  final String time;
  final String energy;
  final String budget;
  final String weather;
  final String cuisine;
  final String spiceLevel;
  final String description;
  final List<String> tags;
  final String imageUrl;
  DateTime? lastCookedAt;

  Recipe({
    required this.id,
    required this.name,
    required this.type,
    required this.time,
    required this.energy,
    required this.budget,
    required this.weather,
    required this.cuisine,
    required this.spiceLevel,
    required this.description,
    required this.tags,
    required this.imageUrl,
    this.lastCookedAt,
  });
}

class UserPreferences {
  final String mood;
  final String time;
  final String energy;
  final String budget;
  final String weather;

  UserPreferences({
    required this.mood,
    required this.time,
    required this.energy,
    required this.budget,
    required this.weather,
  });
}

// Repository Interface
abstract class RecipeRepository {
  Future<List<Recipe>> recommend({
    Set<String> excludeIds,
    required UserPreferences prefs,
    Duration repeatAfter,
    int topN,
  });

  Future<void> markCooked(String recipeId, DateTime when);
}

// InMemory Repository
class InMemoryRecipeRepository implements RecipeRepository {
  final List<Recipe> _recipes;

  InMemoryRecipeRepository(this._recipes);

  // FIXED: Just return the recipes directly since RecipeData.getAllRecipesData()
  // already returns List<Recipe>, not List<Map>
  static List<Recipe> getSampleRecipes() {
    return RecipeData.getAllRecipesData();
  }

  @override
  Future<List<Recipe>> recommend({
    Set<String> excludeIds = const {},
    required UserPreferences prefs,
    Duration repeatAfter = const Duration(days: 3),
    int topN = 3,
  }) async {
    final now = DateTime.now();

    final filtered = _recipes.where((r) {
      if (excludeIds.contains(r.id)) return false;
      if (r.lastCookedAt != null &&
          now.difference(r.lastCookedAt!).inDays < repeatAfter.inDays) {
        return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      int scoreA = _scoreRecipe(a, prefs);
      int scoreB = _scoreRecipe(b, prefs);
      return scoreB.compareTo(scoreA);
    });

    return filtered.take(topN).toList();
  }

  int _scoreRecipe(Recipe recipe, UserPreferences prefs) {
    int score = 0;
    if (recipe.type == prefs.mood) score += 50;
    if (recipe.time == prefs.time) score += 40;
    if (recipe.energy == prefs.energy) score += 30;
    if (recipe.budget == prefs.budget) score += 20;
    if (recipe.weather == prefs.weather) score += 15;
    return score;
  }

  @override
  Future<void> markCooked(String recipeId, DateTime when) async {
    final recipe = _recipes.firstWhere((r) => r.id == recipeId);
    recipe.lastCookedAt = when;
  }
}
// ----------------- UI -----------------
class SuggestionsScreen extends StatefulWidget {
  final RecipeRepository repository;
  final UserPreferences prefs;

  const SuggestionsScreen({
    super.key,
    required this.repository,
    required this.prefs,
  });

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  late Future<List<Recipe>> _suggestions;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  void _loadSuggestions() {
    setState(() {
      _suggestions = widget.repository.recommend(
        prefs: widget.prefs,
        excludeIds: {},
        repeatAfter: const Duration(days: 3),
        topN: 5,
      );
    });
  }

  void _markCooked(Recipe recipe) async {
    await widget.repository.markCooked(recipe.id, DateTime.now());
    _loadSuggestions();
  }

  void _suggestAnother() {
    _loadSuggestions();
  }

  void _saveToHistory(Recipe recipe) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to History!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5E6D3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.restaurant,
                color: Color(0xFFE74C3C),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Your Meal',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Recipe>>(
        future: _suggestions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No suggestions found!",
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            );
          }

          final recipes = snapshot.data!;
          final currentRecipe = recipes[_currentIndex % recipes.length];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Recipe Image Card
                  Container(
                    width: double.infinity,
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFD2691E),
                                  Color(0xFFCD853F),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.restaurant_menu,
                              size: 80,
                              color: Colors.white54,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recipe Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentRecipe.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Perfect for today mood',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFE74C3C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 18,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  currentRecipe.time,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(width: 20),

                            Row(
                              children: [
                                const Icon(
                                  Icons.restaurant,
                                  size: 18,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  currentRecipe.cuisine,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(width: 20),

                            Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Spice: ${currentRecipe.spiceLevel}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        const Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 18,
                              color: Colors.black54,
                            ),
                            SizedBox(width: 6),
                            Text(
                              '4 people',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Text(
                          currentRecipe.description,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 24),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: currentRecipe.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE4D6),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFE74C3C),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _saveToHistory(currentRecipe),
                              borderRadius: BorderRadius.circular(16),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bookmark_border,
                                    color: Colors.black54,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save to\nHistory',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0xFFE74C3C),
                                Color(0xFFC0392B),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE74C3C).withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _currentIndex = (_currentIndex + 1) % recipes.length;
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Suggest\nAnother',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

//-----------------MY APP----------------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsModel>();

    return MaterialApp(
      title: 'Meal Suggestion App',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFFFFF5E1),
        fontFamily: 'Serif',
      ),

      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: const GetStartedScreen(),
      routes: {
        '/auth': (context) => AuthGate(),
        '/home': (context) => HomeScreen(),
        '/questions1': (context) => QuestionsScreen(),
        '/questions2': (context) => Questions2Screen(),
        '/questions3': (context) => Questions3Screen(),
        '/questions4': (context) => Questions4Screen(),
        '/questions5': (context) => Questions5Screen(),
        '/suggestions': (context) => SuggestionsScreen(
          repository: InMemoryRecipeRepository(InMemoryRecipeRepository.getSampleRecipes()),
          prefs: UserPreferences(
            mood: 'Chicken',
            time: '30-35 minutes',
            energy: 'Active',
            budget: 'Medium budget',
            weather: 'Cold',
          ),
        ),
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