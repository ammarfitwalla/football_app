import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    Center(
      child: Text(
        "Search for players nearby based on location or position!",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
    ),
    Center(
      child: Text(
        "Find teams available in your area!",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
    ),
    Center(
      child: Text(
        "Create your team and invite players!",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
    ),
    Center(
      child: Text(
        "View your profile, sport, and position details here.",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome to the Football App!"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _pages[_currentIndex],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Find Players',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Find Teams',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Create Team',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
