import 'package:flutter/material.dart';
import 'task.dart';

class ScoreDetailsScreen extends StatelessWidget {
  final int score;
  final List<Task> tasks;
  final VoidCallback resetScore;

  ScoreDetailsScreen({
    required this.score,
    required this.tasks,
    required this.resetScore,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: Text('Score Details', style: TextStyle(color: Colors.black)),
        // centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20.0),
            Text(
              'Total Score',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            Text(
              score.toString(),
              style: TextStyle(fontSize: 48.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.0),
            Text(
              'Score Breakdown',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            for (Task task in tasks)
              if (task.isCompleted) Text(task.name),
            ElevatedButton(
              // Add this FlatButton widget
              onPressed: resetScore, // Call the resetScore method when pressed
              child: Text('Reset Score'),
            ),
          ],
        ),
      ),
    );
  }
}
