import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'Badges.dart'; // Fixed the import for Badges.dart

class ViewBadgeScreen extends StatefulWidget {
  final String badgeName;
  final String badgeGraphic;
  final String badgeDesc;
  final String badgeUuid;
  final String badgeState;

  const ViewBadgeScreen({super.key, 
    required this.badgeName,
    required this.badgeGraphic,
    required this.badgeDesc,
    required this.badgeUuid,
    required this.badgeState,
  });

  @override
  _ViewBadgeScreenState createState() => _ViewBadgeScreenState();
}

class _ViewBadgeScreenState extends State<ViewBadgeScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();

    // You may want to include logic here to fetch the badge description
    // and update `badgeMessage` accordingly, if it's being fetched asynchronously.
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
                  const SizedBox(height: 0), // Adds space at the top
                  Image.asset(
                    'assets/app_logo.png', // Path to your asset image
                    height: 100,
                  ),
                  const SizedBox(height: 40),
                  // Badge graphic with confetti animation and optional grayscale filter
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: widget.badgeState == 'locked' ? 0.25 : 1.0,
                        child: Image.asset(
                          widget.badgeGraphic,
                          height: 200,
                          width: 200,
                        ),
                      ),
                      // Uncommented ConfettiWidget and fixed indentation
                      // ConfettiWidget(
                      //   confettiController: _confettiController,
                      //   blastDirection: -pi / 2, // upward
                      //   particleDrag: 0.05, // apply drag to the confetti
                      //   emissionFrequency: 0.05, // how often it should emit
                      //   numberOfParticles: 20, // number of particles to emit
                      //   gravity: 0.1, // gravity - or fall speed
                      //   shouldLoop: false,
                      //   colors: const [
                      //     Colors.red,
                      //     Colors.blue,
                      //     Colors.green,
                      //     Colors.yellow,
                      //     Colors.orange,
                      //     Colors.purple,
                      //   ], // manually specify the colors to be used
                      // ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Badge name text
                  Text(
                    widget.badgeState == 'locked' ? '???' : widget.badgeName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  // Badge description text from GET request
                  Text(
                    widget.badgeState == 'locked' ? '???' : widget.badgeDesc,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  // Additional text below the badge details
                  Text(
                    widget.badgeState == 'locked'
                        ? 'You haven\'t unlocked this badge yet, checkin to more pubs to earn it.'
                        : 'You earned this. Show it off!',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 100),
                  // Got it button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.yellow, // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => BadgesScreen()),
                      );
                    },
                    child: const Text(
                      'GOT IT!',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 40), // Adds space at the bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
