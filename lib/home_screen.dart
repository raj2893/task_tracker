import 'package:flutter/material.dart';
import 'package:task_tracker/login_screen.dart';
import 'package:task_tracker/signup_screen.dart';
import 'task.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'score_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  void _editTask(Task task) {
    TextEditingController taskController =
        TextEditingController(text: task.name);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: TextField(
            controller: taskController,
            decoration: const InputDecoration(hintText: 'Enter task'),
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

  @override
  Widget build(BuildContext context) {
    //   return const Scaffold(
    //     body: Center(
    //       child: CircularProgressIndicator(),
    //     ),
    //   );
    // } else if (snapshot.hasError) {
    //   return const Center(
    //     child: Text('Failed to load image'),
    //   );
    // } else {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/loginBG.jpg'), fit: BoxFit.fill),
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
                const Text(
                  'Task Tracker',
                  style: TextStyle(color: Colors.black),
                ),
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
                      icon:
                          const Icon(Icons.account_circle, color: Colors.black),
                    ),
                    GestureDetector(
                      onTap: viewScoreDetails,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          score.toString().padLeft(2, '0'),
                          style: const TextStyle(
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
                          itemBuilder: (BuildContext context, int index) {
                            Task task = taskList[index];
                            return Padding(
                              padding: const EdgeInsets.all(1.0),
                              child: Card(
                                color: const Color.fromARGB(255, 250, 250, 250),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: ListTile(
                                    leading: Checkbox(
                                      value: task.isCompleted,
                                      onChanged: (value) => completeTask(task),
                                    ),
                                    title: Text(
                                      task.name,
                                      style: TextStyle(
                                        fontSize: 17.5,
                                        decoration: task.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: task.isCompleted
                                            ? Colors.grey
                                            : null,
                                      ),
                                    ),
                                    trailing: Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.25,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Expanded(
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Color.fromARGB(
                                                    255, 1, 93, 100),
                                              ),
                                              onPressed: () => _editTask(task),
                                            ),
                                          ),
                                          Expanded(
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Color.fromARGB(
                                                    255, 169, 11, 0),
                                              ),
                                              onPressed: () => deleteTask(task),
                                            ),
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
                                          backgroundColor: const Color.fromARGB(
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
                                            addTask(task);
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
      ),
    );
  }
}
