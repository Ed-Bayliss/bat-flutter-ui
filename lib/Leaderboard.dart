import 'dart:async'; // Import for Timer
import 'dart:io';
import 'dart:ui';
import 'package:burtonaletrail_app/QRScanner.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:burtonaletrail_app/Home.dart'; // Import for navigation
// import 'package:burtonaletrail_app/WebViewPage.dart'; // Import for navigation

class LeaderboardScreen extends StatefulWidget {
  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> leaderboardData = [];
  String? uuid;
  int _selectedIndex = 0; // Set initial index to Home
  bool showInstructionText = true; // Add this line

  @override
  void initState() {
    super.initState();
    fetchLeaderboardData();

    // Set a timer to hide the text after 3 seconds
    Timer(Duration(seconds: 3), () {
      setState(() {
        showInstructionText = false;
      });
    });
  }

  Future<void> fetchLeaderboardData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString('uuid');

    if (uuid == null) {
      throw Exception('UUID is null');
    }

    bool trustSelfSigned = true;
    HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => trustSelfSigned;
    IOClient ioClient = IOClient(httpClient);

    final response = await ioClient.get(Uri.parse(
        'https://burtonaletrail.pawtul.com/leaderboard_data/' + uuid));

    if (response.statusCode == 200) {
      setState(() {
        leaderboardData = json.decode(response.body);
        print(leaderboardData);
      });
    } else {
      throw Exception('Failed to load leaderboard data');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        break;
      case 1:
        // Scan
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => QRScanner()),
        );
        break;
    }
  }

  Widget buildPodium() {
    if (leaderboardData.isEmpty) return Container();

    // Extract the top 3 players
    final topPlayers = leaderboardData[0].take(3).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildPodiumPosition(topPlayers.length > 1 ? topPlayers[1] : null, 2),
        buildPodiumPosition(topPlayers.length > 0 ? topPlayers[0] : null, 1),
        buildPodiumPosition(topPlayers.length > 2 ? topPlayers[2] : null, 3),
      ],
    );
  }

  Widget buildPodiumPosition(dynamic player, int position) {
    final positionColor = position == 1
        ? Colors.black
        : position == 2
            ? Colors.black
            : Colors.black;
    final positionFontSize = position == 1 ? 60.0 : 30.0;

    return Column(
      children: [
        Text(
          position == 1
              ? '🥇'
              : position == 2
                  ? '🥈'
                  : '🥉',
          style: TextStyle(fontSize: positionFontSize),
        ),
        player != null && player['userPoints'] > 0
            ? Column(
                children: [
                  Text(
                    player['userName'],
                    style: TextStyle(color: positionColor),
                  ),
                  Text(
                    '${player['userPoints']}',
                  ),
                ],
              )
            : Column(
                children: [
                  Text(
                    '???',
                    style: TextStyle(color: positionColor),
                  ),
                  Text(
                    '${player['userPoints']}',
                  ),
                ],
              )
      ],
    );
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
          // Foreground content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/app_logo.png', // Path to your asset image
                  height: 200,
                ),
                showInstructionText // Conditionally show the text
                    ? Text(
                        'You can earn points by rating beers or scanning the QR codes at participating pubs to unlock badges.',
                        textAlign: TextAlign.center,
                      )
                    : Container(), // Empty container when text is hidden
                buildPodium(),
                leaderboardData.isEmpty
                    ? CircularProgressIndicator()
                    : Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.zero, // Remove padding
                          itemCount: leaderboardData[0].length,
                          itemBuilder: (context, index) {
                            final item = leaderboardData[0][index];
                            final isCurrentUser =
                                item['userName'] == item['myUserName'];

                            return Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 4.0), // Adjust padding
                              child: Card(
                                color: isCurrentUser
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.1),
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: Stack(
                                  children: [
                                    ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16.0, vertical: 8.0),
                                      leading: CircleAvatar(
                                        radius: 20.0,
                                        backgroundImage: AssetImage(
                                            'assets/images/discoball.gif'),
                                      ),
                                      title: Text(
                                        '${item['userName']}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isCurrentUser
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${item['userPoints']} points',
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          color: isCurrentUser
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (item['userSuppoter'] == 1)
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: Colors.yellow,
                                              size: 16.0,
                                            ),
                                            Text(
                                              'Donated',
                                              style: TextStyle(
                                                color: Colors.yellow,
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      )
              ],
            ),
          ),
          // Bottom Navigation Bar with blur effect
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                  child: BottomNavigationBar(
                    backgroundColor: Colors.transparent,
                    items: const <BottomNavigationBarItem>[
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.qr_code_scanner),
                        label: 'Scan',
                      ),
                    ],
                    currentIndex: _selectedIndex,
                    selectedItemColor: Colors.white,
                    unselectedItemColor: Colors.white,
                    onTap: _onItemTapped,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
