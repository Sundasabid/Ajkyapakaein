import 'package:flutter/material.dart';

// ----------------- Data Models -----------------
class Recipe {
  final String id;
  final String name;
  final String type; // Chicken, Vegetables, Mutton/Beef, Fish/SeaFood
  final String time; // 15-20 minutes, 30-35 minutes, 1 hour, No worry of time
  final String energy; // Low energy, Very low energy, Active
  final String budget; // Low budget, High budget, Very low budget
  final String weather; // Hot, Cold, Rainy, Normal
  final String cuisine; // Indian, Chinese, etc.
  final String spiceLevel; // Mild, Medium, Hot
  final String description;
  final List<String> tags;
  final String imageUrl; // For recipe image
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

// ----------------- Repository Interface -----------------
abstract class RecipeRepository {
  Future<List<Recipe>> recommend({
    Set<String> excludeIds,
    required UserPreferences prefs,
    Duration repeatAfter,
    int topN,
  });

  Future<void> markCooked(String recipeId, DateTime when);
}

// ----------------- InMemory Repository -----------------
class InMemoryRecipeRepository implements RecipeRepository {
  final List<Recipe> _recipes;

  InMemoryRecipeRepository(this._recipes);

  @override
  Future<List<Recipe>> recommend({
    Set<String> excludeIds = const {},
    required UserPreferences prefs,
    Duration repeatAfter = const Duration(days: 3),
    int topN = 3,
  }) async {
    final now = DateTime.now();

    // Filter recently cooked & excluded IDs
    final filtered = _recipes.where((r) {
      if (excludeIds.contains(r.id)) return false;
      if (r.lastCookedAt != null &&
          now
              .difference(r.lastCookedAt!)
              .inDays < repeatAfter.inDays) {
        return false;
      }
      return true;
    }).toList();

    // Sort by score
    filtered.sort((a, b) {
      int scoreA = _scoreRecipe(a, prefs);
      int scoreB = _scoreRecipe(b, prefs);
      return scoreB.compareTo(scoreA);
    });

    return filtered.take(topN).toList();
  }

  int _scoreRecipe(Recipe recipe, UserPreferences prefs) {
    int score = 0;

    // Mood/Type matching (highest priority)
    if (recipe.type == prefs.mood) score += 50;

    // Time matching (very important)
    if (recipe.time == prefs.time) score += 40;

    // Energy level matching (important for cooking feasibility)
    if (recipe.energy == prefs.energy) score += 30;

    // Budget matching (practical consideration)
    if (recipe.budget == prefs.budget) score += 20;

    // Weather matching (seasonal preference)
    if (recipe.weather == prefs.weather) score += 15;

    // Add randomness to avoid same suggestions
    score += (recipe.name.hashCode % 10);

    return score;
  }

  @override
  Future<void> markCooked(String recipeId, DateTime when) async {
    final recipe = _recipes.firstWhere((r) => r.id == recipeId);
    recipe.lastCookedAt = when;
  }


// Sample recipes for demonstration
// static List<Recipe> getSampleRecipes() {
//   return [
//   Recipe(
//     id: '1',
//     name: 'Butter Chicken with Garlic Naan',
//     type: 'Chicken',
//     time: '45 mins',
//     energy: 'Active',
//     budget: 'High budget',
//     weather: 'Cold',
//     cuisine: 'Indian',
//     spiceLevel: 'Medium',
//     description: 'Creamy tomato sauce with tender chicken pieces, flavored with aromatic spices and served with freshly baked garlic naan.',
//     tags: ['Chicken', 'Tomato', 'Cream', 'Spices'],
//     imageUrl: '',
//   ),
//   Recipe(
//   id: '2',
//   name: 'Aloo Gobi',
//   type: 'Vegetables',
//   time: '30-35 minutes',
//   energy: 'Low energy',
//   budget: 'Low budget',
//   weather: 'Normal',
//   cuisine: 'Indian',
//   spiceLevel: 'Mild',
//   description: 'Traditional potato and cauliflower curry with turmeric and spices, perfect for a light meal.',
//   tags: ['Vegetables', 'Potato', 'Cauliflower', 'Turmeric'],
//   imageUrl: '',
//   ),
//   Recipe(
//   id: '3',
//   name: 'Fish Karahi',
//   type: 'Fish/SeaFood',
//   time: '1 hour',
//   energy: 'Active',
//   budget: 'High budget',
//   weather: 'Hot',
//   cuisine: 'Pakistani',
//   spiceLevel: 'Hot',
//   description: 'Fresh fish cooked in traditional karahi style with tomatoes, green chilies and aromatic spices.',
//   tags: ['Fish', 'Tomato', 'Chilies', 'Spices'],
//   imageUrl: '',
//   ),
//   Recipe(
//   id: '4',
//   name: 'Quick Egg Fried Rice',
//   type: 'Vegetables',
//   time: '15-20 minutes',
//   energy: 'Very low energy',
//   budget: 'Very low budget',
//   weather: 'Rainy',
//   cuisine: 'Chinese',
//   spiceLevel: 'Mild',
//   description: 'Simple and quick fried rice with eggs and vegetables, perfect for when you want something fast.',
//   tags: ['Rice', 'Eggs', 'Vegetables'],
//   imageUrl: '',
//   ),
//   Recipe(
//   id: '5',
//   name: 'Mutton Biryani',
//   type: 'Mutton/Beef',
//   time: 'No worry of time',
//   energy: 'Active',
//   budget: 'High budget',
//   weather: 'Cold',
//   cuisine: 'Pakistani',
//   spiceLevel: 'Hot',
//   description: 'Fragrant basmati rice layered with spiced mutton, perfect for special occasions.',
//   tags: ['Mutton', 'Rice', 'Biryani', 'Saffron'],
//   imageUrl: '',
//   ),
//   Recipe(
//   id: '6',
//   name: 'Chicken Biryani',
//   type: 'Chicken',
//   time: '1 hour',
//   energy: 'Active',
//   budget: 'High budget',
//   weather: 'Normal',
//   cuisine: 'Pakistani',
//   spiceLevel: 'Medium',
//   description: 'Aromatic basmati rice cooked with tender chicken and traditional spices.',
//   tags: ['Chicken', 'Rice', 'Biryani', 'Spices'],
//   imageUrl: '',
//   ),
//   Recipe(
//   id: '7',
//   name: 'Dal Chawal',
//   type: 'Vegetables',
//   time: '30-35 minutes',
//   energy: 'Low energy',
//   budget: 'Very low budget',
//   weather: 'Rainy',
//   cuisine: 'Pakistani',
//   spiceLevel: 'Mild',
//   description: 'Simple lentils served with steamed rice, comfort food at its best.',
//   tags: ['Lentils', 'Rice', 'Comfort Food'],
//   imageUrl: '',
//   ),
//   Recipe(
//   id: '8',
//   name: 'Chicken Karahi',
//   type: 'Chicken',
//   time: '30-35 minutes',
//   energy: 'Active',
//   budget: 'High budget',
//   weather: 'Hot',
//   cuisine: 'Pakistani

}