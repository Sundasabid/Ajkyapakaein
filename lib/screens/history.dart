import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../main.dart';
import '../recipe_data.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  List<Recipe> historyItems = [];
  bool isLoading = true;
  late AnimationController _fadeController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadHistoryItems();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh history items every time the screen is accessed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistoryItems();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryItems() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('cooking_history') ?? [];

    setState(() {
      historyItems = historyJson.map((jsonString) {
        final Map<String, dynamic> recipeMap = json.decode(jsonString);
        return Recipe(
          id: recipeMap['id'],
          name: recipeMap['name'],
          type: recipeMap['type'],
          time: recipeMap['time'],
          energy: recipeMap['energy'],
          budget: recipeMap['budget'],
          weather: recipeMap['weather'],
          cuisine: recipeMap['cuisine'],
          spiceLevel: recipeMap['spiceLevel'],
          description: recipeMap['description'],
          tags: List<String>.from(recipeMap['tags']),
          imageUrl: recipeMap['imageUrl'],
          lastCookedAt: recipeMap['lastCookedAt'] != null
              ? DateTime.parse(recipeMap['lastCookedAt'])
              : null,
        );
      }).toList();

      // Sort by most recent first
      historyItems.sort((a, b) {
        if (a.lastCookedAt == null && b.lastCookedAt == null) return 0;
        if (a.lastCookedAt == null) return 1;
        if (b.lastCookedAt == null) return -1;
        return b.lastCookedAt!.compareTo(a.lastCookedAt!);
      });

      isLoading = false;
    });

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _saveHistoryItems() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = historyItems.map((recipe) {
      return json.encode({
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
        'lastCookedAt': recipe.lastCookedAt?.toIso8601String(),
      });
    }).toList();

    await prefs.setStringList('cooking_history', historyJson);
  }

  // Method to add recipe to history (call this from suggestions screen)
  static Future<void> addToHistory(Recipe recipe) async {
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
      final recipeWithTime = Recipe(
        id: recipe.id,
        name: recipe.name,
        type: recipe.type,
        time: recipe.time,
        energy: recipe.energy,
        budget: recipe.budget,
        weather: recipe.weather,
        cuisine: recipe.cuisine,
        spiceLevel: recipe.spiceLevel,
        description: recipe.description,
        tags: recipe.tags,
        imageUrl: recipe.imageUrl,
        lastCookedAt: DateTime.now(),
      );

      historyJson.add(json.encode({
        'id': recipeWithTime.id,
        'name': recipeWithTime.name,
        'type': recipeWithTime.type,
        'time': recipeWithTime.time,
        'energy': recipeWithTime.energy,
        'budget': recipeWithTime.budget,
        'weather': recipeWithTime.weather,
        'cuisine': recipeWithTime.cuisine,
        'spiceLevel': recipeWithTime.spiceLevel,
        'description': recipeWithTime.description,
        'tags': recipeWithTime.tags,
        'imageUrl': recipeWithTime.imageUrl,
        'lastCookedAt': recipeWithTime.lastCookedAt!.toIso8601String(),
      }));
    }

    await prefs.setStringList('cooking_history', historyJson);
  }

  Future<void> _removeFromHistory(String recipeId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Recipe'),
        content: const Text('Are you sure you want to remove this recipe from your history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE74C3C)),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        historyItems.removeWhere((item) => item.id == recipeId);
      });

      await _saveHistoryItems();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Recipe removed from history'),
            ],
          ),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _reSuggestRecipe(Recipe recipe) {
    // Navigate to suggestions with this recipe as preference
    Navigator.pushNamed(
      context,
      '/suggestions',
      arguments: {
        'preferredRecipe': recipe,
        'mood': recipe.type,
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.restaurant_menu, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Finding recipes similar to ${recipe.name}...')),
          ],
        ),
        backgroundColor: const Color(0xFFF6AE2D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _getTimeAgoText(DateTime? cookedAt) {
    if (cookedAt == null) return 'Recently';

    final now = DateTime.now();
    final difference = now.difference(cookedAt);

    if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      return 'Cooked $months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays >= 7) {
      final weeks = (difference.inDays / 7).floor();
      return 'Cooked $weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays >= 1) {
      return 'Cooked ${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours >= 1) {
      return 'Cooked ${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else {
      return 'Cooked just now';
    }
  }

  Color _getRecipeTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'chicken':
        return const Color(0xFFE74C3C);
      case 'vegetables':
        return const Color(0xFF27AE60);
      case 'mutton/beef':
        return const Color(0xFF8E44AD);
      case 'fish/seafood':
        return const Color(0xFF3498DB);
      default:
        return const Color(0xFFF6AE2D);
    }
  }

  String _getRecipeEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'chicken':
        return '🍗';
      case 'vegetables':
        return '🥬';
      case 'mutton/beef':
        return '🥩';
      case 'fish/seafood':
        return '🐟';
      default:
        return '🍛';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black54),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                '🍴',
                style: TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'My History',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE74C3C)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading your cooking history...',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      )
          : historyItems.isEmpty
          ? FadeTransition(
        opacity: _fadeController,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '🍽️',
                    style: TextStyle(fontSize: 50),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No cooking history yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Start cooking recipes to build your\npersonal cooking journey!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/home'),
                icon: const Icon(Icons.restaurant_menu, color: Colors.white),
                label: const Text(
                  'Discover Recipes',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE74C3C),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadHistoryItems,
        color: const Color(0xFFE74C3C),
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: historyItems.length + 1, // +1 for header
          itemBuilder: (context, index) {
            if (index == 0) {
              // Header section
              return FadeTransition(
                opacity: _fadeController,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE74C3C).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.timeline,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${historyItems.length} Recipes Cooked',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Text(
                              'Your cooking journey so far',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final recipe = historyItems[index - 1];
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _slideController,
                curve: Interval(
                  (index - 1) * 0.1,
                  1.0,
                  curve: Curves.easeOutBack,
                ),
              )),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      // Show recipe details bottom sheet
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => _RecipeDetailsSheet(recipe: recipe),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Recipe Image
                          Hero(
                            tag: 'recipe-${recipe.id}',
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: _getRecipeTypeColor(recipe.type).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      _getRecipeTypeColor(recipe.type),
                                      _getRecipeTypeColor(recipe.type).withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getRecipeTypeColor(recipe.type).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _getRecipeEmoji(recipe.type),
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Recipe Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recipe.name.length > 22
                                      ? '${recipe.name.substring(0, 22)}...'
                                      : recipe.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getRecipeTypeColor(recipe.type).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        recipe.cuisine,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _getRecipeTypeColor(recipe.type),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.access_time, size: 12, color: Colors.black54),
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
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule, size: 12, color: Colors.black54),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getTimeAgoText(recipe.lastCookedAt),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Action Buttons
                          Column(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6AE2D).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  onPressed: () => _reSuggestRecipe(recipe),
                                  icon: const Icon(
                                    Icons.refresh,
                                    size: 18,
                                    color: Color(0xFFF6AE2D),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE74C3C).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  onPressed: () => _removeFromHistory(recipe.id),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Color(0xFFE74C3C),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RecipeDetailsSheet extends StatelessWidget {
  final Recipe recipe;

  const _RecipeDetailsSheet({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    recipe.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recipe.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6AE2D).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: Color(0xFFF6AE2D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}