import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:burtonaletrail_app/BeerProfile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:burtonaletrail_app/Home.dart';  // Import for navigation
import 'package:burtonaletrail_app/QRScanner.dart';  // Import for navigation

class PubProfileScreen extends StatefulWidget {
  final String pubId;

  PubProfileScreen({required this.pubId});

  @override
  _PubProfileScreenState createState() => _PubProfileScreenState();
}

class _PubProfileScreenState extends State<PubProfileScreen> {
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
    await fetchPubData();
    await fetchBeerData();

  }

  Future<void> fetchPubData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString('uuid');

    if (uuid != null) {
      bool trustSelfSigned = true;
      HttpClient httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => trustSelfSigned;
      IOClient ioClient = IOClient(httpClient);

      final response = await ioClient.get(Uri.parse('https://burtonaletrail.pawtul.com/pub_data/'+ widget.pubId + "/" + uuid));

      if (response.statusCode == 200) {
        setState(() {
          final List<dynamic> pubDataList = json.decode(response.body);
          if (pubDataList.isNotEmpty) {
            final pubData = pubDataList[0];
            print(pubData);
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

  Future<void> fetchBeerData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString('uuid');

    if (uuid != null) {
      bool trustSelfSigned = true;
      HttpClient httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => trustSelfSigned;
      IOClient ioClient = IOClient(httpClient);

      final response = await ioClient.get(Uri.parse('https://burtonaletrail.pawtul.com/pub_data_beer/' + widget.pubId + '/' + uuid));

      if (response.statusCode == 200) {
        setState(() {
          beerData = json.decode(response.body);
          print(beerData);
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
                            ListView.builder(
  shrinkWrap: true,
  physics: NeverScrollableScrollPhysics(),
  itemCount: beerData[0].length,
  itemBuilder: (context, index) {
    final item = beerData[0][index];
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BeerProfileScreen(beerId: '${item['beerId']}'),
          ),
        );
      },
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: item['beerGraphic'] != null
            ? Image.network(
                '${item['beerGraphic']}',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
            : Container(
                width: 50,
                height: 50,
                color: Colors.grey,
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item['beerName']}',
              style: TextStyle(
                fontSize: 16.0, // Set font size for beer name
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4.0), // Space between name and details
          ],
        ),
        subtitle: RatingBar.builder(
          initialRating: double.parse(item['beerVotesSum']),
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemSize: 20.0, // Change this value to make stars smaller
          itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
          itemBuilder: (context, _) => Icon(
            Icons.star,
            color: Colors.amber,
          ),
          onRatingUpdate: (rating) {
            // You can handle the rating update here if needed
          },
        ),
      ),
    );
  },
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