import 'package:burtonaletrail_app/Home.dart';
import 'package:burtonaletrail_app/Login.dart';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'dart:convert'; // For JSON encoding
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math'; // For random selection

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Burton Ale Trail',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
      },
    );
  }
}
