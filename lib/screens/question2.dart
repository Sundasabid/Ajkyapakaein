import 'package:flutter/material.dart';

class Questions2Screen extends StatefulWidget {
  const Questions2Screen({super.key});

  @override
  State<Questions2Screen> createState() => _Questions2ScreenState();
}

class _Questions2ScreenState extends State<Questions2Screen> {
  String? selectedOption;

  final List<String> moods = ["Low budget", "Medium budget", "High budget", "Very low budget"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),

                // Profile Image
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    image: const DecorationImage(
                      image: NetworkImage(
                        "https://uploadthingy.s3.us-west-1.amazonaws.com/hcFrRBDuLq3kSNzxKBMRw8/icon.jpg",
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  "Aaj Kya Pakayein?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 20),

                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "What is your budget level today?",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Select one option that best matches your preference",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Options
                Expanded(
                  child: ListView(
                    children: moods.map((mood) {
                      final isSelected = selectedOption == mood;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedOption = mood;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 20),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                              colors: [Colors.deepOrange, Colors.orange],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                                : const LinearGradient(
                              colors: [Colors.white, Colors.white],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? Colors.deepOrange.withOpacity(0.4)
                                    : Colors.grey.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              )
                            ],
                            border: Border.all(
                              color: isSelected
                                  ? Colors.deepOrange
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                mood,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                )
                              else
                                const Icon(
                                  Icons.circle_outlined,
                                  color: Colors.grey,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: selectedOption == null
                          ? Colors.grey
                          : Colors.deepOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: selectedOption == null
                        ? null
                        : () {
                      // Get previous answers from route arguments
                      Map<String, String> previousAnswers =
                          ModalRoute.of(context)?.settings.arguments as Map<String, String>? ?? {};

                      // Add current question's answer
                      Map<String, String> completeAnswers = Map.from(previousAnswers);
                      completeAnswers['budget'] = selectedOption!;

                      // Navigate with complete answers
                      Navigator.pushNamed(
                        context,
                        '/questions3',
                        arguments: completeAnswers,
                      );
                    },
                    child: const Text(
                      "Continue",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}