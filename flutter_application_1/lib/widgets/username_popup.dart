import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UsernamePopup extends StatefulWidget {
  final String uid;

  const UsernamePopup({Key? key, required this.uid}) : super(key: key);

  @override
  _UsernamePopupState createState() => _UsernamePopupState();
}

class _UsernamePopupState extends State<UsernamePopup> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  bool _isLoading = false;

Future<void> _saveUsername() async {
  if (_usernameController.text.isEmpty || _displayNameController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("All fields are required.")),
    );
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    final response = await http.post(
      Uri.parse("http://10.0.2.2:8000/users/set-username"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "uid": widget.uid,
        "display_name": _displayNameController.text,
        "username": _usernameController.text,
      }),
    );
    print(response.statusCode);
    print(response.body);
    print(widget.uid);
    print(_displayNameController.text);
    print(_usernameController.text);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"])), // Show success message
      );
      Navigator.pop(context, true); // Return success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${response.body}")),
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
  }
}


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Set Username"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: "Username"),
          ),
          TextField(
            controller: _displayNameController,
            decoration: const InputDecoration(labelText: "Display Name"),
          ),
        ],
      ),
      actions: [
        // TextButton(
        //   onPressed: () => Navigator.pop(context, false), // Cancel action
        //   child: const Text("Cancel"),
        // ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveUsername, // Save action
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text("Save"),
        ),
      ],
    );
  }
}
