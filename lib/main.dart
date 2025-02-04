import 'dart:convert';

import 'package:burtonaletrail_app/AppApi.dart';
import 'package:burtonaletrail_app/Home.dart';
import 'package:burtonaletrail_app/LoadingScreen.dart';
import 'package:burtonaletrail_app/Login.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'package:http/http.dart' as http;

void main() async {
  // Ensure all Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize(
    "3002aa80-35a6-465d-a7dc-6172f15fe72d",
  );
  OneSignal.Notifications.requestPermission(true);

  // Start your Flutter app
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Constructor
  MyApp({Key? key}) : super(key: key);
  final token = Token();

  // Method to get JWT Token
  Future<bool> _validateJwtToken() async {
    bool result = await token.refresh();
    await token.streak();
    return result; // or return false based on your logic
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Burton Ale Trail',
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => HomeScreen(),
      },
      home: FutureBuilder<bool>(
        future: _validateJwtToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: LoadingScreen(
                  loadingText: "Authenticating",
                ),
              ),
            );
          }

          if (snapshot.hasError || snapshot.data == false) {
            return const LoginScreen();
          }

          return HomeScreen();
        },
      ),
    );
  }
}
