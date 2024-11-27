import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationPopup extends StatefulWidget {
  final String uid;

  const LocationPopup({Key? key, required this.uid}) : super(key: key);

  @override
  _LocationPopupState createState() => _LocationPopupState();
}

class _LocationPopupState extends State<LocationPopup> {
  String? selectedCountry;
  String? selectedState;
  String? selectedCity;
  String? selectedArea;

  List<String> countries = [];
  List<String> states = [];
  List<String> cities = [];
  List<String> areas = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCountries();
  }

  Future<void> _fetchCountries() async {
    try {
      final response = await http.get(Uri.parse("http://10.0.2.2:8000/locations/countries"));
      if (response.statusCode == 200) {
        setState(() {
          countries = List<String>.from(json.decode(response.body));
        });
      }
    } catch (e) {
      print("Error fetching countries: $e");
    }
  }

  Future<void> _fetchStates(String country) async {
    try {
      final response = await http.get(Uri.parse("http://10.0.2.2:8000/locations/states?country=$country"));
      if (response.statusCode == 200) {
        setState(() {
          states = List<String>.from(json.decode(response.body));
          selectedState = null;
          selectedCity = null;
          selectedArea = null;
        });
      }
    } catch (e) {
      print("Error fetching states: $e");
    }
  }

  Future<void> _fetchCities(String country, String state) async {
    try {
      final response = await http.get(Uri.parse("http://10.0.2.2:8000/locations/cities?country=$country&state=$state"));
      if (response.statusCode == 200) {
        setState(() {
          cities = List<String>.from(json.decode(response.body));
          selectedCity = null;
          selectedArea = null;
        });
      }
    } catch (e) {
      print("Error fetching cities: $e");
    }
  }

  Future<void> _fetchAreas(String country, String state, String city) async {
    try {
      final response = await http.get(Uri.parse("http://10.0.2.2:8000/locations/areas?country=$country&state=$state&city=$city"));
      if (response.statusCode == 200) {
        setState(() {
          areas = List<String>.from(json.decode(response.body));
          selectedArea = null;
        });
      }
    } catch (e) {
      print("Error fetching areas: $e");
    }
  }

  Future<void> _saveLocation() async {
    if (selectedCountry == null || selectedState == null || selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Country, state, and city are required.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8000/users/set-location"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "uid": widget.uid,
          "country": selectedCountry,
          "state": selectedState,
          "city": selectedCity,
          "area": selectedArea,
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
      print("Error saving location: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Set Location"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            hint: const Text("Select Country"),
            value: selectedCountry,
            items: countries.map((country) {
              return DropdownMenuItem(value: country, child: Text(country));
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCountry = value;
                states = [];
                cities = [];
                areas = [];
              });
              if (value != null) _fetchStates(value);
            },
          ),
          if (states.isNotEmpty)
            DropdownButton<String>(
              hint: const Text("Select State"),
              value: selectedState,
              items: states.map((state) {
                return DropdownMenuItem(value: state, child: Text(state));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedState = value;
                  cities = [];
                  areas = [];
                });
                if (value != null) _fetchCities(selectedCountry!, value);
              },
            ),
          if (cities.isNotEmpty)
            DropdownButton<String>(
              hint: const Text("Select City"),
              value: selectedCity,
              items: cities.map((city) {
                return DropdownMenuItem(value: city, child: Text(city));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCity = value;
                  areas = [];
                });
                if (value != null) _fetchAreas(selectedCountry!, selectedState!, value);
              },
            ),
          if (areas.isNotEmpty)
            DropdownButton<String>(
              hint: const Text("Select Area (Optional)"),
              value: selectedArea,
              items: areas.map((area) {
                return DropdownMenuItem(value: area, child: Text(area));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedArea = value;
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
          onPressed: _isLoading ? null : _saveLocation, // Save action
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text("Save"),
        ),
      ],
    );
  }
}
