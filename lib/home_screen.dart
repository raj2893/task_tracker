import 'package:flutter/material.dart';
import 'package:task_tracker/login_screen.dart';
import 'package:task_tracker/signup_screen.dart';
import 'task.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'score_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

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

  List<String> motivationalQuotes = [
    "The only way to do great work is to love what you do.",
    "Don't watch the clock; do what it does. Keep going.",
    "The future depends on what you do today.",
    "Believe you can and you're halfway there.",
    "Success is not final, failure is not fatal: It is the courage to continue that counts."
  ];

  String quote = '';
  bool isNewUser = false;

  @override
  void initState() {
    super.initState();
    initializePreferences();
    getRandomQuote();
    taskList = [];
    score = 0;
    loadTasksFromFirestore();
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
                ))
            .toList();
        final scoreDoc = snapshot.docs.firstWhere((doc) => doc.id == 'score');

        setState(() {
          taskList = tasks;
          score = scoreDoc?.data()['score'] ?? 0;
        });
      } else {
        setState(() {
          taskList = [];
          score = 0;
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

  void getRandomQuote() {
    setState(() {
      quote = motivationalQuotes[Random().nextInt(motivationalQuotes.length)];
    });
  }

  Future<void> addTask(String taskName) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      final collection = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('taskList');

      final docRef = await collection.add({
        'name': taskName,
        'isCompleted': false,
      });

      print('Task added with ID: ${docRef.id}');

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
          score -= 5;
        }
        taskList.remove(task);
      });

      await collection.doc(task.id).delete(); // Use the task's id

      await collection.doc('taskList').update({
        'tasks': taskList.map((task) => task.toJson()).toList(),
      });

      await collection.doc('score').set({
        'score': score,
      });
    }
  }

  void _editTask(Task task) {
    TextEditingController taskController =
        TextEditingController(text: task.name);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Task'),
          content: TextField(
            controller: taskController,
            decoration: InputDecoration(hintText: 'Enter task'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
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
                    });

                    await collection.doc(task.id).update({
                      'name':
                          updatedTaskName, // Update the task name in Firestore
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
              child: Text('Save Changes'),
            ),
          ],
        );
      },
    );
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

  Future<void> checkNewUser() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      final collection = _firestore.collection('users');
      final doc = await collection.doc(currentUser.uid).get();
      if (doc.exists) {
        setState(() {
          isNewUser = false;
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

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        'https://firebasestorage.googleapis.com/v0/b/task-tracker-c89e2.appspot.com/o/backgroundImage%2FloginBG.jpg?alt=media&token=c1b8e80f-08fd-4db9-98c1-472beb903cda';

    return FutureBuilder<void>(
        future: precacheImage(NetworkImage(imageUrl), context),
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load image'),
            );
          } else {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                      image: NetworkImage(imageUrl), fit: BoxFit.fill),
                ),
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  resizeToAvoidBottomInset: false,
                  appBar: AppBar(
                    elevation: 0.5,
                    backgroundColor: Colors.white,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Task Tracker',
                          style: TextStyle(color: Colors.black),
                        ),
                        Row(
                          children: [
                            PopupMenuButton(
                              iconSize: 40,
                              offset: Offset(0, 50),
                              itemBuilder: (BuildContext context) {
                                return [
                                  PopupMenuItem(
                                    child: TextButton(
                                      onPressed: () {
                                        _authService.signOut();
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  SignupScreen()),
                                        );
                                      },
                                      child: Text('SignUp/Login'),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    child: TextButton(
                                      onPressed: () => _signOut(),
                                      child: Text('SignOut'),
                                    ),
                                  ),
                                ];
                              },
                              icon: Icon(Icons.account_circle,
                                  color: Colors.black),
                            ),
                            GestureDetector(
                              onTap: viewScoreDetails,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.black, width: 1.5),
                                ),
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  score.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black),
                                ),
                              ),
                            ),
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
                              ? const Center(child: Text('No tasks found'))
                              : ListView.builder(
                                  itemCount: taskList.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    Task task = taskList[index];
                                    return Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Card(
                                        color: const Color.fromARGB(
                                            255, 250, 250, 250),
                                        child: ListTile(
                                          leading: Checkbox(
                                            value: task.isCompleted,
                                            onChanged: (value) =>
                                                completeTask(task),
                                          ),
                                          title: Text(
                                            task.name,
                                            style: TextStyle(
                                              decoration: task.isCompleted
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              color: task.isCompleted
                                                  ? Colors.grey
                                                  : null,
                                            ),
                                          ),
                                          trailing: Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.25,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Expanded(
                                                  child: IconButton(
                                                    icon: Icon(Icons.edit),
                                                    onPressed: () =>
                                                        _editTask(task),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: IconButton(
                                                    icon: Icon(Icons.delete),
                                                    onPressed: () =>
                                                        deleteTask(task),
                                                  ),
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
                              child: Text(
                                "Welcome to Task Tracker! \nDon't wait to add your first task! Click on the + button below to get started.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 20),
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
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                quote,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        Container(
                          margin: EdgeInsets.fromLTRB(0, 0, 0,
                              MediaQuery.of(context).size.height * 0.02),
                          child: IntrinsicHeight(
                            child: IntrinsicWidth(
                              child: ElevatedButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    isScrollControlled: true,
                                    context: context,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16.0)),
                                    ),
                                    builder: (BuildContext context) {
                                      TextEditingController taskController =
                                          TextEditingController();
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
                                                decoration: InputDecoration(
                                                  hintText: 'Enter task',
                                                ),
                                              ),
                                              SizedBox(height: 16.0),
                                              ElevatedButton(
                                                onPressed: () {
                                                  String task = taskController
                                                      .text
                                                      .trim();
                                                  if (task.isNotEmpty) {
                                                    addTask(task);
                                                    Navigator.of(context).pop();
                                                  }
                                                },
                                                child: Text('Add Task'),
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
                                      Color.fromARGB(255, 1, 93, 100),
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
              ),
            );
          }
        });
  }
}
