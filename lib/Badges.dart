import 'dart:io';
import 'dart:ui';
import 'package:burtonaletrail_app/ViewBadge.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:burtonaletrail_app/Home.dart'; // Import for navigation
import 'package:burtonaletrail_app/QRScanner.dart'; // Import for navigation

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  _BadgesScreenState createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  List<dynamic> badgeData = [];
  String? uuid;
  String userName = '';
  String userPoints = '0';
  String userPosition = '0';
  String badgeUuid = '';
  String badgeState = 'locked';
  String eventId = '';
  int _selectedIndex = 0; // Set initial index to Home

  @override
  void initState() {
    super.initState();
    // _fetchUserData();
    fetchBadgeData();
  }

  Future<void> fetchBadgeData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString('uuid');

    if (uuid != null) {
      bool trustSelfSigned = true;
      HttpClient httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => trustSelfSigned;
      IOClient ioClient = IOClient(httpClient);

      final response = await ioClient.get(
          Uri.parse('https://burtonaletrail.pawtul.com/badge_data/$uuid'));

      if (response.statusCode == 200) {
        setState(() {
          badgeData = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load badge data');
      }
    } else {
      throw Exception('UUID not found');
    }
  }

  void _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    uuid = prefs.getString('uuid');
    final response = await http.get(
        Uri.parse('https://burtonaletrail.pawtul.com/total_points/${uuid!}'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data[0]);
      setState(() {
        userName = data[0]['userName'] ?? '';
        userPoints = data[0]['userPoints'] ?? '0';
        userPosition = data[0]['userPosition'] ?? '0';
      });
    } else {
      print('Failed to load user data');
    }
  }

  String getSuffix(int number) {
    if (11 <= number % 100 && number % 100 <= 13) {
      return 'th';
    } else {
      switch (number % 10) {
        case 1:
          return 'st';
        case 2:
          return 'nd';
        case 3:
          return 'rd';
        default:
          return 'th';
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const QRScanner()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    int position = int.tryParse(userPosition) ?? 0;
    String positionSuffix = getSuffix(position);

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/backdrop.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Foreground content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/app_logo.png',
                  height: 200,
                ),
                const SizedBox(height: 10),
                badgeData.isEmpty
                    ? const CircularProgressIndicator()
                    : Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: badgeData[0].length +
                              2, // Extra items for group headers
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              // First header
                              return const Padding(
                                padding:
                                    EdgeInsets.symmetric(vertical: 10.0),
                                child: Text(
                                  'September 2024',
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            } else if (index == 4) {
                              // Second header
                              return const Padding(
                                padding:
                                    EdgeInsets.symmetric(vertical: 10.0),
                                child: Text(
                                  'March 2024',
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            } else {
                              // Adjust index to account for headers
                              final adjustedIndex =
                                  index > 4 ? index - 2 : index - 1;
                              final item = badgeData[0][adjustedIndex];

                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 10.0),
                                child: Opacity(
                                  opacity: item['badgeState'] == 'locked'
                                      ? 0.25
                                      : 1.0,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 0),
                                    leading: SizedBox(
                                      width: 50,
                                      height: 50,
                                      child: item['badgeGraphic'] != null
                                          ? Image.asset(
                                              '${item['badgeGraphic']}',
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 50,
                                              height: 50,
                                              color: Colors.grey,
                                            ),
                                    ),
                                    title: Text(
                                      '${item['badgeName']}',
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.black,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${item['badgeDesc']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    onTap: () {
                                      // Add your onTap logic here.
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ViewBadgeScreen(
                                              badgeUuid: item['badgeId'],
                                              badgeName: item['badgeName'],
                                              badgeDesc: item['badgeDesc'],
                                              badgeGraphic:
                                                  item['badgeGraphic'],
                                              badgeState: item['badgeState']),
                                        ),
                                      );
                                      // For example, navigate to another screen or show a dialog with more details.
                                    },
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                const SizedBox(height: 80),
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
