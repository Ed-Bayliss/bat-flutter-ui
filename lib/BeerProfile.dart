import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:burtonaletrail_app/Home.dart';  // Import for navigation
import 'package:burtonaletrail_app/QRScanner.dart';  // Import for navigation

class BeerProfileScreen extends StatefulWidget {
  final String beerId;

  BeerProfileScreen({required this.beerId});

  @override
  _BeerProfileScreenState createState() => _BeerProfileScreenState();
}

class _BeerProfileScreenState extends State<BeerProfileScreen> {
  String? pubName;
  String? pubDescription;
  String? pubLandlord;
  String? landlordPhoneNumber;
  String? openingTimes;
  String? pubLogo;

  String? beerId;
  String? beerName;
  String? beerBrewery;
  String? beerAbv;
  String? beerDesc;
  String? beerGraphic;

  String? uuid;

  List<dynamic> beerData = [];

  int _selectedIndex = 0;  // Set initial index to Home
  bool isLoading = true;
 
  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    await fetchBeerData();
  }

  Future<void> fetchBeerData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString('uuid');

    if (uuid != null) {
      final response = await http.get(Uri.parse('https://burtonaletrail.pawtul.com/beer_data/${widget.beerId}/$uuid'));

      if (response.statusCode == 200) {
        setState(() {
          final List<dynamic> pubDataList = json.decode(response.body);
          if (pubDataList.isNotEmpty) {
            final pubData = pubDataList[0];
            pubName = pubData['pubName'];
            pubDescription = pubData['pubDescription'];
            pubLandlord = pubData['pubLandlord'];
            landlordPhoneNumber = pubData['pubPhone'];
            openingTimes = pubData['pubOpen'];
            pubLogo = pubData['pubLogo'];
            isLoading = false;
          }
        });
      } else {
        throw Exception('Failed to load pub data');
      }
    } else {
      throw Exception('UUID not found');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
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
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero, // Remove padding
                          children: [
                            pubLogo != null
                                ? Image.asset(
                                    pubLogo!,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  )
                                : Container(),
                            SizedBox(height: 20),
                            Text(
                              pubName ?? '',
                              style: TextStyle(
                                fontSize: 24.0, // Set font size for title
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              pubDescription ?? '',
                              style: TextStyle(
                                fontSize: 16.0, // Set font size for description
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              "Landlord: ${pubLandlord ?? ''}",
                              style: TextStyle(
                                fontSize: 18.0, // Set font size for landlord info
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              "Phone: ${landlordPhoneNumber ?? ''}",
                              style: TextStyle(
                                fontSize: 18.0, // Set font size for phone number
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              "Opening Times:",
                              style: TextStyle(
                                fontSize: 18.0, // Set font size for opening times title
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              openingTimes ?? '',
                              style: TextStyle(
                                fontSize: 16.0, // Set font size for opening times
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              "Beers Available:",
                              style: TextStyle(
                                fontSize: 18.0, // Set font size for beers title
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
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