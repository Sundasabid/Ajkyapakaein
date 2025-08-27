import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

import '../main.dart';
import '../recipe_data.dart';
import '../model/user_profile.dart';
import 'history.dart';

class SuggestionScreen extends StatefulWidget {
  const SuggestionScreen({super.key});

  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  Recipe? suggestedRecipe;
  bool isLoading = true;
  Map<String, dynamic>? userAnswers;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Using a post-frame callback ensures that ModalRoute.of(context) is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Get the user answers from route arguments (if any)
      userAnswers = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _getSuggestion();
    });
  }

  Future<void> _saveToHistory(Recipe recipe) async {
    try {
      print('Saving recipe to history: ${recipe.name}');

      // Save directly to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('cooking_history') ?? [];

      // Check if recipe already exists
      bool exists = false;
      for (int i = 0; i < historyJson.length; i++) {
        final Map<String, dynamic> existing = json.decode(historyJson[i]);
        if (existing['id'] == recipe.id) {
          // Update existing recipe's lastCookedAt
          existing['lastCookedAt'] = DateTime.now().toIso8601String();
          historyJson[i] = json.encode(existing);
          exists = true;
          break;
        }
      }

      if (!exists) {
        // Add new recipe to history
        historyJson.add(json.encode({
          'id': recipe.id,
          'name': recipe.name,
          'type': recipe.type,
          'time': recipe.time,
          'energy': recipe.energy,
          'budget': recipe.budget,
          'weather': recipe.weather,
          'cuisine': recipe.cuisine,
          'spiceLevel': recipe.spiceLevel,
          'description': recipe.description,
          'tags': recipe.tags,
          'imageUrl': recipe.imageUrl,
          'lastCookedAt': DateTime.now().toIso8601String(),
        }));
      }

      await prefs.setStringList('cooking_history', historyJson);
      print('Recipe saved to SharedPreferences successfully');

      // Increment meals count in profile
      if (context.mounted) {
        context.read<UserProfile>().incrementMeals();
        print('Meals count incremented');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.history, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Saved to History!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving to history: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving to history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _getSuggestion() {
    setState(() {
      isLoading = true;
    });

    // Check if we have user answers - if not, create default ones
    Map<String, dynamic> answers = userAnswers ?? {
      'energy': 'Active',
      'time': '30-35 minutes',
      'budget': 'Medium budget',
      'weather': 'Normal',
      'mood': 'Chicken'
    };

    final allRecipes = RecipeData.getAllRecipesData();
    print('Total recipes loaded: ${allRecipes.length}');

    // --- IMPROVED SCORING LOGIC ---
    // Calculate a score for each recipe based on how many answers it matches.
    var scoredRecipes = allRecipes.map((recipe) {
      int score = 0;

      // Check each answer and give points for matches
      if (answers['energy'] != null && recipe.energy == answers['energy']) score += 5;
      if (answers['time'] != null && recipe.time == answers['time']) score += 4;
      if (answers['budget'] != null && recipe.budget == answers['budget']) score += 3;
      if (answers['weather'] != null && recipe.weather == answers['weather']) score += 3;
      if (answers['mood'] != null && recipe.type == answers['mood']) score += 5;

      return {'recipe': recipe, 'score': score};
    }).toList();

    // Sort by score (highest first)
    scoredRecipes.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    // Find the highest score achieved by any recipe.
    int maxScore = scoredRecipes.isNotEmpty ? scoredRecipes.first['score'] as int : 0;

    // Get recipes with the highest score, or if no matches, get top 10
    List<Recipe> bestMatches;
    if (maxScore > 0) {
      // Get all recipes with the highest score
      bestMatches = scoredRecipes
          .where((item) => item['score'] == maxScore)
          .map((item) => item['recipe'] as Recipe)
          .toList();
    } else {
      // If no matches, take top 10 recipes randomly
      bestMatches = scoredRecipes.take(10).map((item) => item['recipe'] as Recipe).toList();
    }

    // Select a random recipe from the best matches.
    final random = Random();
    final recipe = bestMatches[random.nextInt(bestMatches.length)];

    print('Selected recipe: ${recipe.name}');
    print('Recipe image URL: ${recipe.imageUrl}');
    print('Image URL is empty: ${recipe.imageUrl.isEmpty}');

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          suggestedRecipe = recipe;
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chef's Suggestion",
            style:
            TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.deepOrange)
              : suggestedRecipe == null
              ? const Text("Couldn't find a recipe. Try again!",
              style: TextStyle(fontSize: 18, color: Colors.black54))
              : buildRecipeCard(suggestedRecipe!),
        ),
      ),
    );
  }

  Widget buildRecipeCard(Recipe recipe) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image
            if (recipe.imageUrl.isNotEmpty)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: recipe.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFD2691E),
                            Color(0xFFCD853F),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFD2691E),
                            Color(0xFFCD853F),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.restaurant_menu,
                          size: 60,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              recipe.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            // Recipe Details Row
            Row(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      recipe.time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      recipe.spiceLevel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.restaurant,
                      size: 16,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      recipe.cuisine,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              recipe.description,
              style:
              TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recipe.tags
                  .map((tag) => Chip(
                label: Text(tag),
                backgroundColor: Colors.deepOrange.withOpacity(0.1),
                labelStyle: const TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.w600),
              ))
                  .toList(),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.bookmark_border, color: Colors.white),
                  label: const Text("Save to History",
                      style: TextStyle(color: Colors.white)),
                  onPressed: () => _saveToHistory(recipe),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                ElevatedButton(
                  child: const Text("Try Again",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: _getSuggestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}