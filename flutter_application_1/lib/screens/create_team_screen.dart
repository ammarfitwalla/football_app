import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({Key? key}) : super(key: key);

  @override
  _CreateTeamScreenState createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final ApiService _apiService = ApiService(); // Instance for API calls
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchResults = []; // Stores search results
  List<String> _selectedPlayers = []; // Stores selected players (max 11)
  String? _teamLogoPath; // Path for the uploaded team logo image

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Team"),
        actions: [
          TextButton(
            onPressed: _saveTeam, // Call save team function
            child: const Text(
              "Save",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Team Name with Logo Uploader
              Row(
                children: [
                  GestureDetector(
                    onTap: _uploadLogo, // Call logo upload function
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _teamLogoPath == null
                          ? const Icon(Icons.camera_alt, size: 30, color: Colors.grey)
                          : Image.network(
                              _teamLogoPath!,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _teamNameController,
                      decoration: const InputDecoration(
                        labelText: "Team Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Search Bar for Players
              TextField(
                controller: _searchController,
                onChanged: _searchPlayers, // Trigger search on typing
                decoration: const InputDecoration(
                  labelText: "Search Players",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              // Selected Players List
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _selectedPlayers.map((player) {
                  return Chip(
                    label: Text(player),
                    onDeleted: () {
                      setState(() {
                        _selectedPlayers.remove(player);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Search Results (add to selected players)
              if (_searchResults.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Search Results:"),
                    ..._searchResults.map((player) {
                      return ListTile(
                        title: Text(player),
                        trailing: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            if (_selectedPlayers.length < 11) {
                              setState(() {
                                _selectedPlayers.add(player);
                                _searchResults.remove(player);
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Maximum of 11 players can be added."),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ),
              const SizedBox(height: 16),
              // Save and Cancel Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: _saveTeam,
                    child: const Text("Save Team"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to search players from the API
  Future<void> _searchPlayers(String query) async {
    try {
      final results = await _apiService.searchPlayers(query);
      setState(() {
        _searchResults = results; // Update search results
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error searching players: $e")),
      );
    }
  }

  // Function to upload team logo
  Future<void> _uploadLogo() async {
    // Simulating logo upload
    // You can integrate file picker or image picker library here
    setState(() {
      _teamLogoPath =
          "https://via.placeholder.com/60"; // Replace with actual file path after uploading
    });
  }

  // Function to save the team
  Future<void> _saveTeam() async {
    if (_teamNameController.text.isEmpty || _selectedPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter team name and select players.")),
      );
      return;
    }

    try {
      await _apiService.createTeam({
        "name": _teamNameController.text,
        "logo": _teamLogoPath,
        "players": _selectedPlayers,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Team created successfully.")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving team: $e")),
      );
    }
  }
}
