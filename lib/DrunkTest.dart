import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:burtonaletrail_app/Home.dart';
import 'package:burtonaletrail_app/Leaderboard.dart';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TappingGamePage extends StatefulWidget {
  const TappingGamePage({super.key});

  @override
  _TappingGamePageState createState() => _TappingGamePageState();
}

class _TappingGamePageState extends State<TappingGamePage> {
  double topPosition = 100;
  double leftPosition = 100;
  int level = 1; // Starting level with 100 seconds
  Timer? timer;
  bool isGameOver = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    startTimer(level);

    // Simulate loading time for assets (you can replace this with actual loading logic if needed)
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  void startTimer(int level) {
    var time = 1000;
    if (level > 6) {
      time = 900;
    }
    if (level > 10) {
      time = 800;
    }
    if (level > 14) {
      time = 700;
    }
    if (level > 18) {
      time = 600;
    }
    if (level > 20) {
      time = 800;
    }
    if (level > 25) {
      time = 700;
    }
    if (level > 30) {
      time = 600;
    }
    if (level > 34) {
      time = 500;
    }
    timer = Timer(Duration(milliseconds: time), () {
      setState(() {
        isGameOver = true;
      });
    });
  }

  Future<void> postScores() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString('uuid');

    if (uuid == null) {
      throw Exception('UUID not found');
    }

    bool trustSelfSigned = true;
    HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => trustSelfSigned;
    IOClient ioClient = IOClient(httpClient);

    // Check the current game score status
    final response = await ioClient.get(
        Uri.parse('https://burtonaletrail.pawtul.com/gamescores/check/$uuid'));

    if (response.statusCode == 200) {
      var responseBody = jsonDecode(response.body)[0]['status'];

      // Handle status, assuming it's an int (1 for true, 0 for false)
      if (responseBody == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'You can continue playing this but you\'ve already claimed your points.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Post new score
        final postResponse = await ioClient.get(
          Uri.parse(
              'https://burtonaletrail.pawtul.com/gamescores/${level * 10}/$uuid'),
        );

        if (postResponse.statusCode == 200) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LeaderboardScreen(),
            ),
          );
        } else {
          throw Exception('Failed to post the score');
        }
      }
    } else {
      throw Exception('Failed to load game score status');
    }
  }

  void resetGame() {
    setState(() {
      level = 1;
      isGameOver = false;
      moveImage();
      startTimer(level);
    });
  }

  void moveImage() {
    final random = Random();
    setState(() {
      topPosition =
          random.nextDouble() * (MediaQuery.of(context).size.height - 100);
      leftPosition =
          random.nextDouble() * (MediaQuery.of(context).size.width - 100);
    });
  }

  void onImageTapped() {
    if (timer?.isActive ?? false) {
      timer?.cancel();
      setState(() {
        if (level > 0.1) {
          level = level + 1;
          moveImage();
          startTimer(level);
        } else {
          isGameOver = true;
        }
      });
    }
  }

  String getLevelMessage() {
    return "Level $level Points ${level * 10}";
  }

  Color getLevelColor() {
    if (level > 1) {
      return Colors.red;
    } else if (level > 3) {
      return Colors.redAccent;
    } else if (level > 6) {
      return Colors.amber.shade700;
    } else if (level > 10) {
      return Colors.amber;
    } else if (level > 12) {
      return Colors.yellow.shade700;
    } else if (level > 15) {
      return Colors.yellow;
    } else if (level > 25) {
      return Colors.green.shade700;
    } else if (level > 30) {
      return Colors.green;
    } else if (level > 40) {
      return Colors.lightGreen;
    } else {
      return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Background image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/backdrop.jpg', // Path to your background image
                    fit:
                        BoxFit.cover, // Makes the image cover the entire screen
                  ),
                ),
                // Foreground content
                // Column(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     Image.asset(
                //       'assets/app_logo.png', // Path to your asset image
                //       height: 200,
                //     ),
                //   ],
                // ),
                if (!isGameOver)
                  Positioned(
                    top: 200,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        getLevelMessage(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: getLevelColor(),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: topPosition,
                  left: leftPosition,
                  child: GestureDetector(
                    onTap: onImageTapped,
                    child: Image.asset(
                      'assets/images/discoball.gif',
                      width: 75,
                      height: 75,
                    ),
                  ),
                ),
                if (isGameOver)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'You must tap the mirror ball as many times as possible.',
                          style: TextStyle(fontSize: 12),
                        ),
                        const Text(
                          'You can only claim these points once.',
                          style: TextStyle(fontSize: 12),
                        ),
                        const Text(
                          'So make it count.',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          'You reached level $level',
                          style: const TextStyle(fontSize: 32),
                        ),
                        ElevatedButton(
                          onPressed: resetGame,
                          child: const Text('Try Again'),
                        ),
                        ElevatedButton(
                          onPressed: postScores,
                          child: Text('Claim ${level * 10} Points'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HomeScreen()),
                            );
                          },
                          child: const Text('Exit'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
