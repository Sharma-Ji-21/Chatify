import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../screens/chat_screen.dart';
import '../screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    "users",
  );
  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;

  List<UserModel> userList = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  void fetchUsers() {
    _dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final List<UserModel> loadedUsers = [];

      data.forEach((key, value) {
        if (key != _currentUid) {
          loadedUsers.add(UserModel.fromMap(Map<String, dynamic>.from(value)));
        }
      });

      setState(() {
        userList = loadedUsers;
      });
    });
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Available Users",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: logout,
                      icon: const Icon(Icons.logout, color: Colors.white),
                      tooltip: "Logout",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Expanded(
                child: userList.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.tealAccent,
                        ),
                      )
                    : ListView.builder(
                        itemCount: userList.length,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemBuilder: (context, index) {
                          final user = userList[index];
                          return Card(
                            color: Colors.white10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: const CircleAvatar(
                                backgroundColor: Colors.tealAccent,
                                child: Icon(Icons.person, color: Colors.black),
                              ),
                              title: Text(
                                user.username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                user.email,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      receiverId: user.uid,
                                      receiverEmail: user.email,
                                      receiverName: user.username,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
