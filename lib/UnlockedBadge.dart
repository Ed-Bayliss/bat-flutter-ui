import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:burtonaletrail_app/QRScanner.dart';

class UnlockedBadgeScreen extends StatefulWidget {
  final String badgeName;
  final String badgeGraphic;
  final String badgePoints;
  final String badgeDesc;

  UnlockedBadgeScreen({
    required this.badgeName,
    required this.badgeGraphic,
    required this.badgePoints,
    required this.badgeDesc,
  });

  @override
  _UnlockedBadgeScreenState createState() => _UnlockedBadgeScreenState();
}

class _UnlockedBadgeScreenState extends State<UnlockedBadgeScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/backdrop.jpg', // Path to your background image
              fit: BoxFit.cover, // Makes the image cover the entire screen
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Logo image near the top
                  SizedBox(height: 0), // Adds space at the top
                  Image.asset(
                    'assets/app_logo.png', // Path to your asset image
                    height: 100,
                  ),
                  SizedBox(height: 40),
                  // Badge graphic with confetti animation
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        widget.badgeGraphic, // Assuming badgeGraphic is a URL
                        height: 200,
                        width: 200,
                      ),
                      ConfettiWidget(
                        confettiController: _confettiController,
                        blastDirection: -pi / 2, // upward
                        particleDrag: 0.05, // apply drag to the confetti
                        emissionFrequency: 0.05, // how often it should emit
                        numberOfParticles: 20, // number of particles to emit
                        gravity: 0.1, // gravity - or fall speed
                        shouldLoop: false,
                        colors: const [
                          Colors.red,
                          Colors.blue,
                          Colors.green,
                          Colors.yellow,
                          Colors.orange,
                          Colors.purple
                        ], // manually specify the colors to be used
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Badge name text
                  Text(
                    widget.badgeName,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  // Badge points text
                  Text(
                    '${widget.badgePoints}',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  // Additional text below the badge details
                  Text(
                    'Congratulations! You’ve proven your skills and unlocked a special badge',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  // Got it button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.yellow, // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => QRScanner()),
                      );
                    },
                    child: Text(
                      'GOT IT!',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  SizedBox(height: 40), // Adds space at the bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}