import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PositionPopup extends StatefulWidget {
  final String uid;

  const PositionPopup({Key? key, required this.uid}) : super(key: key);

  @override
  _PositionPopupState createState() => _PositionPopupState();
}

class _PositionPopupState extends State<PositionPopup> {
  String? selectedPosition;
  List<String> positions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPositions();
  }

  Future<void> _fetchPositions() async {
    try {
      final response = await http.get(Uri.parse("http://10.0.2.2:8000/positions/get-positions"));
      if (response.statusCode == 200) {
        setState(() {
          positions = List<String>.from(json.decode(response.body));
        });
      }
    } catch (e) {
      print("Error fetching positions: $e");
    }
  }

  Future<void> _savePosition() async {
    if (selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Position is required.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8000/users/set-position"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "uid": widget.uid,
          "position": selectedPosition,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"])),
        );
        Navigator.pop(context, true); // Return success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.body}")),
        );
      }
    } catch (e) {
      print("Error saving position: $e");
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
      title: const Text("Set Position"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            hint: const Text("Select Position"),
            value: selectedPosition,
            items: positions.map((position) {
              return DropdownMenuItem(value: position, child: Text(position));
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedPosition = value;
              });
            },
          ),
        ],
      ),
      actions: [
        // TextButton(
        //   onPressed: () => Navigator.pop(context, false), // Cancel action
        //   child: const Text("Cancel"),
        // ),
        ElevatedButton(
          onPressed: _isLoading ? null : _savePosition, // Save action
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text("Save"),
        ),
      ],
    );
  }
}
