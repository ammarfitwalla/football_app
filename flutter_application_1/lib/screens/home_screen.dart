import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/username_popup.dart';
import '../widgets/location_popup.dart';
import '../widgets/position_popup.dart';

class GoogleBottomBar extends StatefulWidget {
  final String uid; // Pass UID from login

  const GoogleBottomBar({Key? key, required this.uid}) : super(key: key);

  @override
  State<GoogleBottomBar> createState() => _GoogleBottomBarState();
}

class _GoogleBottomBarState extends State<GoogleBottomBar> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _checkMissingDetails(); // Trigger popups when the app loads
  }

  Future<void> _checkMissingDetails() async {
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/users/check-details?uid=${widget.uid}"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<String> missingDetails = List<String>.from(data['missing_details']);

        // Show popups sequentially based on missing details
        if (missingDetails.contains("username")) {
          await _showUsernamePopup();
        }
        if (missingDetails.contains("location")) {
          await _showLocationPopup();
        }
        if (missingDetails.contains("position")) {
          await _showPositionPopup();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error checking details: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _showUsernamePopup() async {
    final success = await showDialog(
      context: context,
      builder: (context) => UsernamePopup(uid: widget.uid),
    );

    if (success == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username updated successfully.")),
      );
    }
  }

  Future<void> _showLocationPopup() async {
    final success = await showDialog(
      context: context,
      builder: (context) => LocationPopup(uid: widget.uid),
    );

    if (success == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location updated successfully.")),
      );
    }
  }

  Future<void> _showPositionPopup() async {
    final success = await showDialog(
      context: context,
      builder: (context) => PositionPopup(uid: widget.uid),
    );

    if (success == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Position updated successfully.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create_team'); // FAB navigates to Create Team
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 5,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 0) {
              _checkMissingDetails(); // Check missing details when Home tab is selected
            }
            setState(() {
              _currentIndex = index;
            });
            _pageController.jumpToPage(index);
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search Players"),
            BottomNavigationBarItem(icon: Icon(Icons.groups), label: "Search Teams"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
              child: SingleChildScrollView(
                child: Center(child: const Text("Home Screen")), // Replace with your Home screen widget
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
              child: SingleChildScrollView(
                child: Center(child: const Text("Search Players")), // Replace with your Search Players widget
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
              child: SingleChildScrollView(
                child: Center(child: const Text("Search Teams")), // Replace with your Search Teams widget
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
              child: SingleChildScrollView(
                child: Center(child: const Text("Profile")), // Replace with your Profile widget
              ),
            ),
          ],
        ),
      ),
    );
  }
}