import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:task_tracker/login_screen.dart';
import 'package:task_tracker/signup_screen.dart';
import 'package:task_tracker/utilities/colors.dart';
import 'task.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'score_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
// import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> taskList = [];
  int score = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String backgroundImagePath = '';
  // bool isImageLoading = true;
  late Timer _timer;
  String? userProfileImageUrl;
  // List<String> motivationalQuotes = [
  //   "The only way to do great work is to love what you do.",
  //   "Don't watch the clock; do what it does. Keep going.",
  //   "The future depends on what you do today.",
  //   "Believe you can and you're halfway there.",
  //   "Success is not final, failure is not fatal: It is the courage to continue that counts."
  // ];

  String quote = '';
  String _quote = 'Loading...';
  bool isNewUser = false;

  @override
  void initState() {
    super.initState();
    initializePreferences();
    // getRandomQuote();
    taskList = [];
    score = 0;
    loadTasksFromFirestore();
    _fetchRandomQuote();
    _startTimer();
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        setState(() {
          userProfileImageUrl = user.photoURL;
        });
      } else {
        setState(() {
          userProfileImageUrl = null;
        });
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Update the UI periodically here
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer
        .cancel(); // Don't forget to cancel the timer when the widget is disposed
    super.dispose();
  }

  void _fetchRandomQuote() async {
    try {
      // Replace 'YOUR_API_ENDPOINT' with the actual URL of your API that provides random quotes.
      var url = Uri.parse('https://zenquotes.io/api/quotes/');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        // Assuming your API response is in the format: {"quote": "Your random quote here"}
        List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final randomIndex = Random().nextInt(data.length);
          setState(() {
            _quote = data[randomIndex]['q'];
          });
        } else {
          setState(() {
            _quote = 'No quotes Available';
          });
        }
      } else {
        // Handle the case when the API call fails.
        setState(() {
          _quote = 'Failed to fetch quote';
        });
      }
    } catch (e) {
      // Handle any exceptions that occur during the API call.
      setState(() {
        _quote = 'Error: $e';
      });
    }
  }

  Future<void> initializePreferences() async {
    await checkNewUser();
    await loadTasksFromFirestore();
  }

  Future<void> loadTasksFromFirestore() async {
    final User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      final collection = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('taskList');

      final snapshot = await collection.get();

      if (snapshot.docs.isNotEmpty) {
        final tasks = snapshot.docs
            .where((doc) => doc.id != 'score')
            .map((doc) => Task(
                  id: doc.id,
                  name: doc.data()['name'],
                  isCompleted: doc.data()['isCompleted'],
                  deadline: doc.data()['deadline'] != null
                      ? DateTime.parse(doc.data()['deadline'])
                      : null,
                ))
            .toList();
        final scoreDoc = snapshot.docs.firstWhere((doc) => doc.id == 'score');

        setState(() {
          taskList = tasks;
          score = scoreDoc.data()['score'] ?? 0;
        });
      } else {
        setState(() {
          taskList = [];
          score = 0;
          setState(() {
            isNewUser = true;
          });
        });
      }
      final scoreDoc = await collection.doc('score').get();
      if (!scoreDoc.exists) {
        await collection.doc('score').set({
          'score': score,
        });
      }
    }
  }

  // void getRandomQuote() {
  //   setState(() {
  //     quote = motivationalQuotes[Random().nextInt(motivationalQuotes.length)];
  //   });
  // }

  Future<void> completeTask(Task task) async {
    final User? currentUser = _auth.currentUser;
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('taskList');

    setState(() {
      if (!task.isCompleted) {
        task.isCompleted = true;
        score += 5;
      } else {
        task.isCompleted = false;
        score -= 5;
      }
    });

    await collection.doc(task.id).update({
      'isCompleted': task.isCompleted,
    });

    await collection.doc('score').update({
      'score': score,
    });

    await collection.doc('taskList').update({
      'tasks': taskList.map((task) => task.toJson()).toList(),
      'score': score,
    });
  }

  Future<void> deleteTask(Task task) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      final collection = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('taskList');

      setState(() {
        if (task.isCompleted) {
          setState(() {
            score -= 5;
          });
        }
        taskList.remove(task);
      });

      await collection.doc(task.id).delete(); // Use the task's id

      // await collection.doc('taskList').update({
      //   'tasks': taskList.map((task) => task.toJson()).toList(),
      // });

      await collection.doc('score').set({
        'score': score,
      });

      await collection.doc('taskList').update({
        'tasks': taskList.map((task) => task.toJson()).toList(),
        'score': score,
      });
    }
  }

  Future<void> resetScore() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      final collection = _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('taskList');

      setState(() {
        score = 0;
        for (Task task in taskList) {
          task.isCompleted = false;
          collection.doc(task.id).update({'isCompleted': false});
        }
      });

      await collection.doc('score').set({
        'score': score,
      });

      await collection.doc('taskList').update({
        'tasks': taskList.map((task) => task.toJson()).toList(),
        'score': score,
      });
    }
  }

  Future<void> addTask(String taskName, DateTime? deadline) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      final collection = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('taskList');

      final docRef = await collection.add({
        'name': taskName,
        'isCompleted': false,
        'deadline': deadline?.toIso8601String(),
      });

      print('Task added with ID: ${docRef.id}');

      print(userProfileImageUrl);

      final task = Task(
        id: docRef.id,
        name: taskName,
        isCompleted: false,
      );

      setState(() {
        taskList.add(task);
        if (taskList.length == 1) {
          score = 0; // Set score to 0 if it's the first task
        }
      });

      await collection.doc(docRef.id).update({
        'id': docRef.id,
      });

      await collection.doc('taskList').update({
        'tasks': taskList.map((task) => task.toJson()).toList(),
      });

      // Create the score document if it doesn't exist
      final scoreDoc = await collection.doc('score').get();
      if (!scoreDoc.exists) {
        await collection.doc('score').set({
          'score': score,
        });
      }
    }
  }

  void _editTask(Task task) {
    TextEditingController taskController =
        TextEditingController(text: task.name);

    DateTime selectedDate = task.deadline ?? DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: taskController,
                decoration: const InputDecoration(hintText: 'Enter task'),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return Container(
                        height: 300,
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.date,
                          initialDateTime: DateTime.now(),
                          onDateTimeChanged: (DateTime newDate) {
                            selectedDate = newDate;
                          },
                        ),
                      );
                    },
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Deadline:'),
                    Text(
                      '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String updatedTaskName = taskController.text.trim();
                if (updatedTaskName.isNotEmpty) {
                  final User? currentUser = _auth.currentUser;
                  if (currentUser != null) {
                    final collection = _firestore
                        .collection('users')
                        .doc(currentUser.uid)
                        .collection('taskList');

                    setState(() {
                      task.name = updatedTaskName;
                      task.deadline = selectedDate;
                    });

                    await collection.doc(task.id).update({
                      'name': updatedTaskName,
                      'deadline': selectedDate
                          .toIso8601String(), // Update the task name in Firestore
                    });

                    Navigator.pop(context);

                    // Update the score in Firestore
                    await collection.doc('taskList').update({
                      'tasks': taskList.map((task) => task.toJson()).toList(),
                      'score': score, // Save the updated score to Firestore
                    });
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> checkNewUser() async {
    final User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      final collection = _firestore.collection('users');
      final doc = await collection.doc(currentUser.uid).get();

      if (doc.exists) {
        setState(() {
          isNewUser = false;
        });
      } else {
        setState(() {
          isNewUser = true;
        });
      }
    }
  }

  Future<void> viewScoreDetails() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScoreDetailsScreen(
          score: score,
          tasks: taskList,
          resetScore: resetScore,
        ),
      ),
    );
  }

  void _signOut() async {
    await _authService.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void _signoutLogin() async {
    await _authService.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SignupScreen()),
    );
  }

  void showUserOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => _signoutLogin(),
                child: const Text('SignUp/Login'),
              ),
              TextButton(
                onPressed: () => _signOut(),
                child: const Text('SignOut'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Container(
          decoration:
              const BoxDecoration(color: Color.fromARGB(255, 24, 61, 61)),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              elevation: 0.1,
              backgroundColor: const Color.fromARGB(255, 24, 61, 61),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Task Tracker',
                    style: GoogleFonts.ubuntu(
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 201, 255, 238),
                        fontSize: 24),
                  ),
                  if (userProfileImageUrl == null)
                    Row(
                      children: [
                        PopupMenuButton(
                          iconSize: 40,
                          offset: const Offset(0, 50),
                          itemBuilder: (BuildContext context) {
                            return [
                              PopupMenuItem(
                                child: TextButton(
                                  onPressed: () => _signoutLogin(),
                                  child: const Text('SignUp/Login'),
                                ),
                              ),
                              PopupMenuItem(
                                child: TextButton(
                                  onPressed: () => _signOut(),
                                  child: const Text('SignOut'),
                                ),
                              ),
                            ];
                          },
                          icon: Icon(Icons.account_circle, color: iconColor),
                        ),
                        GestureDetector(
                          onTap: viewScoreDetails,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: iconColor, width: 1.5),
                            ),
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              score.toString().padLeft(2, '0'),
                              style: TextStyle(fontSize: 14, color: iconColor),
                            ),
                          ),
                        )
                      ],
                    )
                  else
                    Row(
                      children: [
                        PopupMenuButton(
                          color: cardColor,
                          offset: const Offset(0, 50),
                          itemBuilder: (BuildContext context) {
                            return [
                              PopupMenuItem(
                                child: TextButton(
                                  onPressed: () => _signoutLogin(),
                                  child: Text(
                                    'SignUp/Login',
                                    style: GoogleFonts.ubuntu(color: textColor),
                                  ),
                                ),
                              ),
                              PopupMenuItem(
                                child: TextButton(
                                  onPressed: () => _signOut(),
                                  child: Text(
                                    'SignOut',
                                    style: GoogleFonts.ubuntu(color: textColor),
                                  ),
                                ),
                              ),
                            ];
                          },
                          child: Padding(
                            padding: EdgeInsets.all(5),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2.0),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    25), // Half of the width and height
                                child: Image.network(
                                  userProfileImageUrl!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 40,
                          child: GestureDetector(
                            onTap: viewScoreDetails,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: iconColor, width: 1.5),
                              ),
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(
                                  score.toString(),
                                  style:
                                      TextStyle(fontSize: 16, color: iconColor),
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                ],
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: taskList.isEmpty
                        ? const Center(
                            child: Text(
                            'No tasks found',
                            style: TextStyle(color: Colors.white),
                          ))
                        : ListView.builder(
                            itemCount: taskList.length,
                            itemBuilder: (BuildContext context, int index) {
                              Task task = taskList[index];
                              Duration? remainingDuration;
                              double progress = 0.0;
                              if (task.deadline != null &&
                                  task.deadline!.isAfter(DateTime.now())) {
                                remainingDuration =
                                    task.deadline!.difference(DateTime.now());
                                int totalDurationInSeconds = task.deadline!
                                    .difference(DateTime.now())
                                    .inSeconds;
                                progress = 1.0 -
                                    (remainingDuration.inSeconds /
                                        totalDurationInSeconds);
                              }
                              return Dismissible(
                                onDismissed: (direction) {
                                  deleteTask(task);
                                },
                                key: ValueKey(task.id),
                                child: Padding(
                                  padding: const EdgeInsets.all(1),
                                  child: Card(
                                    color: cardColor,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: ListTile(
                                              leading: Checkbox(
                                                value: task.isCompleted,
                                                onChanged: (value) =>
                                                    completeTask(task),
                                                activeColor: iconColor,
                                                checkColor: Colors.black,
                                              ),
                                              title: Text(
                                                task.name,
                                                style: GoogleFonts.ubuntu(
                                                  fontSize: 17.5,
                                                  fontWeight: FontWeight.w400,
                                                  decoration: task.isCompleted
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null,
                                                  color: task.isCompleted
                                                      ? Color.fromARGB(
                                                          255, 3, 36, 9)
                                                      : textColor,
                                                ),
                                              ),
                                              trailing: task.deadline != null
                                                  ? Container(
                                                      width: 30,
                                                      height: 30,
                                                      child:
                                                          CircularProgressIndicator(
                                                        value: task.deadline!
                                                                .isAfter(
                                                                    DateTime
                                                                        .now())
                                                            ? progress
                                                            : 1.0,
                                                        backgroundColor:
                                                            Colors.grey[300],
                                                        color: Colors.blue,
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit,
                                              color: iconColor,
                                            ),
                                            onPressed: () => _editTask(task),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              color: iconColor,
                                            ),
                                            onPressed: () => deleteTask(task),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (isNewUser)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey[200],
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: const Text(
                          "Welcome to Task Tracker! \nDon't wait to add your first task! Click on the + button below to get started.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            color: Color.fromARGB(255, 1, 93, 100),
                          ),
                        ),
                      ),
                    ),
                  if (!isNewUser)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey[200],
                        ),
                        padding: const EdgeInsets.all(10.0),
                        child: TextButton(
                          onPressed: _fetchRandomQuote,
                          child: Text(
                            "\" $_quote \"",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              color: Color.fromARGB(255, 1, 93, 100),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Container(
                    margin: EdgeInsets.fromLTRB(
                        0, 0, 0, MediaQuery.of(context).size.height * 0.02),
                    child: IntrinsicHeight(
                      child: IntrinsicWidth(
                        child: ElevatedButton(
                          onPressed: () {
                            showModalBottomSheet(
                              isScrollControlled: true,
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16.0)),
                              ),
                              builder: (BuildContext context) {
                                TextEditingController taskController =
                                    TextEditingController();
                                DateTime? selectedDate;
                                return SingleChildScrollView(
                                  child: Container(
                                    padding: EdgeInsets.only(
                                      bottom: MediaQuery.of(context)
                                          .viewInsets
                                          .bottom,
                                      left: 16.0,
                                      right: 16.0,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: taskController,
                                          decoration: const InputDecoration(
                                            hintText: 'Enter task',
                                          ),
                                        ),
                                        const SizedBox(height: 16.0),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(
                                                    255, 1, 93, 100),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20.0),
                                            ),
                                          ),
                                          onPressed: () {
                                            String task =
                                                taskController.text.trim();
                                            if (task.isNotEmpty) {
                                              if (selectedDate != null) {
                                                // Check if a date is selected
                                                addTask(task,
                                                    selectedDate); // Pass the selectedDate to addTask
                                              } else {
                                                addTask(task,
                                                    null); // No deadline selected
                                              }

                                              Navigator.of(context).pop();
                                            }
                                          },
                                          child: const Text('Add Task'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 1, 93, 100),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50.0),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.add),
                              SizedBox(width: 5.0),
                              Text('Add Task')
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
