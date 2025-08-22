import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../main.dart';
import '../recipe_data.dart';
import '../model/user_profile.dart';

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
      // Get the user answers from route arguments
      userAnswers = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _getSuggestion();
    });
  }

  Future<void> addRecipeToHistory(Recipe recipe) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('cooking_history') ?? [];

    // To prevent duplicates, remove the recipe if it already exists in history.
    historyJson.removeWhere((item) {
      final decoded = jsonDecode(item) as Map<String, dynamic>;
      return decoded['id'] == recipe.id;
    });

    // Add the new recipe to the top of the list.
    final recipeMap = {
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
    };
    historyJson.insert(0, jsonEncode(recipeMap));

    await prefs.setStringList('cooking_history', historyJson);
  }

  Future<void> _toggleFavorite(Recipe recipe) async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList('favorite_recipes') ?? [];

    if (favoriteIds.contains(recipe.id)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('This recipe is already in your favorites!'),
          backgroundColor: Colors.orangeAccent));
    } else {
      favoriteIds.add(recipe.id);
      await prefs.setStringList('favorite_recipes', favoriteIds);
      context.read<UserProfile>().incrementFavorites();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Added to your favorites!'),
          backgroundColor: Colors.green));
    }
  }

  void _getSuggestion() {
    setState(() {
      isLoading = true;
    });

    // Check if we have user answers - if not, create default ones
    Map<String, dynamic> answers = userAnswers ?? {};

    final allRecipes = RecipeData.getAllRecipesData();

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

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          suggestedRecipe = recipe;
          isLoading = false;
        });

        // Add to history and update profile stats AFTER the suggestion is shown
        addRecipeToHistory(recipe);
        context.read<UserProfile>().incrementMeals();
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
            Text(
              recipe.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
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
                  icon: const Icon(Icons.favorite_border, color: Colors.white),
                  label: const Text("Favorite",
                      style: TextStyle(color: Colors.white)),
                  onPressed: () => _toggleFavorite(recipe),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
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