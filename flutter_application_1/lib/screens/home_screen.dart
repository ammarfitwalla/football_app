import 'package:flutter/material.dart';

class GoogleBottomBar extends StatefulWidget {
  const GoogleBottomBar({Key? key}) : super(key: key);

  @override
  State<GoogleBottomBar> createState() => _GoogleBottomBarState();
}

class _GoogleBottomBarState extends State<GoogleBottomBar> {
  int _selectedIndex = 0;

  final _screens = [
    Center(child: Text("Home Screen")),
    Center(child: Text("Search Players")),
    Center(child: Text("Search Teams")),
    Center(child: Text("Profile Screen")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Football App')),
      body: _screens[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Create Team screen
          Navigator.pushNamed(context, '/create_team');
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomBarItem(Icons.home, "Home", 0),
            _buildBottomBarItem(Icons.search, "Search Players", 1),
            const SizedBox(width: 40), // Spacer for FAB
            _buildBottomBarItem(Icons.group, "Search Teams", 2),
            _buildBottomBarItem(Icons.person, "Profile", 3),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBarItem(IconData icon, String label, int index) {
    return IconButton(
      onPressed: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      icon: Icon(
        icon,
        color: _selectedIndex == index ? Colors.blue : Colors.grey,
      ),
    );
  }
}
