import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/username_popup.dart';
import '../widgets/location_popup.dart';
import '../widgets/position_popup.dart';
import 'home_screen.dart'; // Import GoogleBottomBar

class PopupHandler extends StatefulWidget {
  final String uid;

  const PopupHandler({Key? key, required this.uid}) : super(key: key);

  @override
  State<PopupHandler> createState() => _PopupHandlerState();
}

class _PopupHandlerState extends State<PopupHandler> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkMissingDetails(); // Trigger the popups
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
    } finally {
      setState(() {
        _isLoading = false;
      });

      // Navigate to the Home Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GoogleBottomBar(uid: widget.uid),
        ),
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
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text("Redirecting to Home..."),
      ),
    );
  }
}
