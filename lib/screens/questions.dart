import 'package:flutter/material.dart';

class QuestionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Answer Questions')),
      body: Column(
        children: [
          Text('Question 1: ...'),
          // Add more questions here
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/suggestion'); // After last question
            },
            child: Text('Show Suggestion'),
          ),
        ],
      ),
    );
  }
}
