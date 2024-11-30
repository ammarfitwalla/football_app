import 'dart:async'; // For Timer
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/player_card.dart'; // Adjust the path based on your project structure

class SearchPlayersPage extends StatefulWidget {
  final String uid;

  const SearchPlayersPage({Key? key, required this.uid}) : super(key: key);

  @override
  State<SearchPlayersPage> createState() => _SearchPlayersPageState();
}

class _SearchPlayersPageState extends State<SearchPlayersPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _players = [];
  bool _isLoading = false;

  Timer? _debounce; // Timer for debouncing

  // Filters
  String? _country;
  String? _state;
  String? _city;
  bool _ageFilterEnabled = false;
  RangeValues _ageRange = const RangeValues(18, 40);
  bool _positionFilterEnabled = false;
  List<String> _positions = [];
  List<String> _selectedPositions = [];

  @override
  void initState() {
    super.initState();
    _fetchUserLocation(); // Fetch current user's location
    _fetchPositions(); // Fetch positions for the filter dropdown
  }

  @override
  void dispose() {
    _debounce?.cancel(); // Cancel the debounce timer if active
    _searchController.dispose(); // Dispose of the controller
    super.dispose();
  }

  Future<void> _fetchUserLocation() async {
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/users/get-location?uid=${widget.uid}"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _country = data['country'];
          _state = data['state'];
          _city = data['city'];
        });
        _searchPlayers(); // Automatically fetch players after getting location
      } else {
        print("Error fetching user location: ${response.body}");
      }
    } catch (e) {
      print("Error fetching user location: $e");
    }
  }

  Future<void> _fetchPositions() async {
    try {
      final response = await http.get(Uri.parse("http://10.0.2.2:8000/positions/get-positions"));
      if (response.statusCode == 200) {
        setState(() {
          _positions = List<String>.from(json.decode(response.body));
        });
      }
    } catch (e) {
      print("Error fetching positions: $e");
    }
  }

void _onSearchChanged(String query) {
  // Cancel the previous debounce timer if it is still active
  if (_debounce?.isActive ?? false) _debounce!.cancel();

  // Start a new debounce timer
  _debounce = Timer(const Duration(milliseconds: 700), () {
    // Call _searchPlayers regardless of the query length
    _searchPlayers();
  });
}


  Future<void> _searchPlayers() async {
    if (_country == null || _state == null || _city == null) {
      print("Location filters are not available. Returning early.");
      return; // Ensure location filters are available
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Log the request body before sending the request
      final requestBody = json.encode({
        "query": _searchController.text,
        "country": _country,
        "state": _state,
        "city": _city,
        "role": "player",
        "age_filter": _ageFilterEnabled ? [_ageRange.start, _ageRange.end] : null,
        "position_filter": _positionFilterEnabled ? _selectedPositions : null, // Ensure selected positions are passed
      });

      print("Sending request to search players with body: $requestBody"); // Log the request body to confirm
      print("Selected positions for filter: $_selectedPositions"); // Log selected positions

      final response = await http.post(
        Uri.parse("http://10.0.2.2:8000/players/search"),
        headers: {"Content-Type": "application/json"},
        body: requestBody,
      );

      print("Response status: ${response.statusCode}");
      if (response.statusCode == 200) {
        print("Received response: ${response.body}");
        setState(() {
          _players = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        print("Error: ${response.body}");
      }
    } catch (e) {
      print("Error searching players: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Find Players"),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged, // Use debounce
              decoration: const InputDecoration(
                labelText: "Search Players",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          // Filters
          ExpansionTile(
            title: const Text("Filters"),
            children: [
              // Age Range Filter
              SwitchListTile(
                title: const Text("Age Range"),
                value: _ageFilterEnabled,
                onChanged: (value) {
                  setState(() {
                    _ageFilterEnabled = value;
                  });
                },
              ),
              if (_ageFilterEnabled)
                RangeSlider(
                  values: _ageRange,
                  min: 18,
                  max: 50,
                  divisions: 32,
                  labels: RangeLabels(
                    _ageRange.start.round().toString(),
                    _ageRange.end.round().toString(),
                  ),
                  onChanged: (values) {
                    setState(() {
                      _ageRange = values;
                    });
                  },
                ),
              // Position Filter
              SwitchListTile(
                title: const Text("Position"),
                value: _positionFilterEnabled,
                onChanged: (value) {
                  setState(() {
                    _positionFilterEnabled = value;
                    print("Position filter enabled: $value");
                  });
                },
              ),
              if (_positionFilterEnabled)
                Wrap(
                  spacing: 8.0,
                  children: _positions.map((position) {
                    return FilterChip(
                      label: Text(position),
                      selected: _selectedPositions.contains(position),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedPositions.add(position);
                            print("Added position: $position"); // Log added position
                          } else {
                            _selectedPositions.remove(position);
                            print("Removed position: $position"); // Log removed position
                          }
                        });
                        // Trigger the API call when position filter is changed
                        _searchPlayers();
                      },
                    );
                  }).toList(),
                ),
            ],
          ),
          const Divider(),
          // Player Cards
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _players.isEmpty
                    ? const Center(child: Text("No players found."))
                    : ListView.builder(
                        itemCount: _players.length,
                        itemBuilder: (context, index) {
                          final player = _players[index];
                          return PlayerCard(
                            displayName: player['display_name'] ?? "Unknown",
                            username: player['username'] ?? "Unknown",
                            position: player['position'] ?? "Unknown",
                            location: player['location'] ?? "Unknown",
                            email: player['email'] ?? "Unknown",
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
