import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:task_tracker/utilities/colors.dart';
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
        elevation: 0.1,
        backgroundColor: bgColor,

        title: Column(
          children: [
            Text(
              'Score Details',
              style: GoogleFonts.ubuntu(
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 201, 255, 238),
                  fontSize: 24),
            ),
          ],
        ),
        // centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: bgColor,
        ),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              Container(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.25,
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  color: cardColor,
                  child: Column(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Card(
                              color: textColor,
                              child: const Padding(
                                padding: EdgeInsets.all(5),
                                child: Text(
                                  '#Task Score :-',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 0, 46, 84),
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            score.toString(),
                            style: GoogleFonts.lobster(
                              fontSize: 50.0,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: TextButton(
                            // Add this FlatButton widget
                            onPressed:
                                resetScore, // Call the resetScore method when pressed
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                      padding: const EdgeInsets.all(5),
                                      color: textColor,
                                      child: const Row(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(right: 5),
                                            child: Icon(CupertinoIcons.refresh,
                                                color: Color.fromARGB(
                                                    255, 0, 46, 84)),
                                          ),
                                          Text(
                                            'Reset Score',
                                            style: TextStyle(
                                              color: Color.fromARGB(
                                                  255, 0, 46, 84),
                                            ),
                                          ),
                                        ],
                                      )),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              Row(children: [
                SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                Container(
                  height: MediaQuery.of(context).size.height * 0.0015,
                  width: MediaQuery.of(context).size.width * 0.4,
                  color: textColor,
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                Container(
                  height: MediaQuery.of(context).size.height * 0.0015,
                  width: MediaQuery.of(context).size.width * 0.06,
                  color: textColor,
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                Container(
                  height: MediaQuery.of(context).size.height * 0.0015,
                  width: MediaQuery.of(context).size.width * 0.4,
                  color: textColor,
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.04),
              ]),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              Expanded(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.95,
                  child: Card(
                      // color: const Color.fromARGB(255, 255, 217, 183),
                      color: cardColor,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15))),
                      child: Column(
                        children: [
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.015),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                CupertinoIcons.check_mark_circled_solid,
                                color: Colors.white,
                              ),
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.02),
                              Text(
                                'Score Breakdown',
                                style: GoogleFonts.ubuntu(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(
                                        255, 218, 255, 251)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20.0),
                          Expanded(
                            child: ListView.separated(
                              separatorBuilder: (context, index) {
                                // Add a separator between items
                                return const Divider(
                                  color: Colors.white,
                                  height: 1,
                                  thickness: 1,
                                );
                              },
                              itemCount: tasks.length,
                              itemBuilder: (context, index) {
                                final task = tasks[index];

                                if (task.isCompleted) {
                                  final completedTaskIndex = tasks
                                      .take(index + 1)
                                      .where((t) => t.isCompleted)
                                      .toList()
                                      .length;
                                  return Card(
                                    color: const Color.fromARGB(
                                        255, 218, 255, 251),
                                    child: Padding(
                                      padding: const EdgeInsets.all(30),
                                      child: Text(
                                        '${completedTaskIndex}. ${task.name}',
                                        style: GoogleFonts.ubuntu(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromARGB(
                                              255, 0, 17, 48),
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  // If the task is not completed, return an empty container.
                                  return Container();
                                }
                              },
                            ),
                          )
                        ],
                      )),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
