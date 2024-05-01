import 'package:flutter_dotenv/flutter_dotenv.dart';

// Define a nullable global variable
String? _apiUrl;

// Define a function to safely assign the global variable after dotenv is loaded
void initializeConfig() {
  _apiUrl = dotenv.env['API_URL_DEV'] ?? "http://localhost:3001";
}

// Define a getter to access the global variable
String get apiUrl {
  if (_apiUrl == null) {
    throw Exception('Attempted to access API URL before initialization');
  }
  return _apiUrl!;
}
