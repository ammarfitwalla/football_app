import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://your-fastapi-url.com";

Future<List<String>> searchPlayers(String query) async {
  final response = await http.get(
    Uri.parse("http://your-fastapi-url.com/players/search?q=$query"),
  );
  if (response.statusCode == 200) {
    return List<String>.from(json.decode(response.body));
  } else {
    throw Exception("Failed to fetch players");
  }
}


Future<void> createTeam(Map<String, dynamic> teamData) async {
  final response = await http.post(
    Uri.parse("http://your-fastapi-url.com/teams"),
    headers: {"Content-Type": "application/json"},
    body: json.encode(teamData),
  );
  if (response.statusCode != 201) {
    throw Exception("Failed to create team");
  }
}
}