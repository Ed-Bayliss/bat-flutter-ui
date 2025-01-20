import 'dart:convert';

import 'package:burtonaletrail_app/AppApi.dart';
import 'package:burtonaletrail_app/Home.dart';
import 'package:burtonaletrail_app/Login.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Constructor
  MyApp({Key? key}) : super(key: key);

  // Method to get JWT Token
  Future<bool> _validateJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final access_token = prefs.getString('access_token');
    final refresh_token = prefs.getString('refresh_token');

    if (access_token == null) {
      // No token found
      return false;
    }

    final url = Uri.parse(
        apiServerJWTValidate); // Replace with your actual server endpoint

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $access_token', // Adjust if your server expects a different auth header
        },
        body: jsonEncode({
          'access_token': access_token,
          'refresh_token': refresh_token
        }), // Adjust based on your server's expected payload
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['access_token'] != null) {
          final accessToken = jsonResponse['access_token'];
          final refreshToken = jsonResponse['refresh_token'];
          // Store the access token in shared preferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', accessToken);
          await prefs.setString('refresh_token', refreshToken);
        }
        return true;
      } else {
        // Token is invalid or other error
        print('Token validation failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      // Handle any errors during the HTTP request
      print('Error validating token: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Burton Ale Trail',
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
      },
      home: FutureBuilder<bool>(
        future: _validateJwtToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError || snapshot.data == false) {
            return LoginScreen();
          }

          return HomeScreen();
        },
      ),
    );
  }
}
