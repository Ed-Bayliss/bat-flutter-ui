import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:burtonaletrail_app/Home.dart'; // Import for navigation
import 'package:burtonaletrail_app/QRScanner.dart'; // Import for navigation
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

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
  String? beerVotesSum;
  String? beerPubs;

  String? uuid;

  List<dynamic> beerData = [];

  int _selectedIndex = 0; // Set initial index to Home
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
      bool trustSelfSigned = true;
      HttpClient httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => trustSelfSigned;
      IOClient ioClient = IOClient(httpClient);

      final response = await ioClient.get(Uri.parse(
          'https://burtonaletrail.pawtul.com/beer_data/' +
              widget.beerId +
              "/" +
              uuid));

      if (response.statusCode == 200) {
        setState(() {
          final List<dynamic> pubDataList = json.decode(response.body);
          if (pubDataList.isNotEmpty) {
            final beerData = pubDataList[0];
            print(beerData);
            beerName = beerData['beerName'];
            beerBrewery = beerData['beerBrewery'];
            beerAbv = beerData['beerAbv'];
            beerDesc = beerData['beerDesc'];
            beerGraphic = beerData['beerGraphic'];
            beerVotesSum = beerData['beerVotesSum'];
            beerPubs = beerData['beerPubs'];
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

  Future<void> submitRating(double rating) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString('uuid');

    if (uuid != null) {
      bool trustSelfSigned = true;
      HttpClient httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => trustSelfSigned;
      IOClient ioClient = IOClient(httpClient);

      final response = await ioClient.get(
        Uri.parse('https://burtonaletrail.pawtul.com/beer_vote/' +
            widget.beerId +
            '/' +
            rating.toString() +
            '/' +
            uuid),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
            content: Text('Rating submitted successfully!'),
          ),
        );
      } else if (response.statusCode == 700) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
            content: Text('Your vote was changed, no points were added.'),
          ),
        );
      } else if (response.statusCode == 600) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
            content: Text('The event has not yet started.'),
          ),
        );
      } else {
        throw Exception('Failed to submit rating');
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
                    fit:
                        BoxFit.cover, // Makes the image cover the entire screen
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
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: ListView(
                            padding: EdgeInsets.zero, // Remove padding
                            children: [
                              beerGraphic != null
                                  ? Image.network(
                                      beerGraphic!,
                                      height: 200,
                                      fit: BoxFit.contain,
                                    )
                                  : Container(),
                              SizedBox(height: 20),
                              Center(
                                child: Text(
                                  beerName ?? '',
                                  style: TextStyle(
                                    fontSize: 24.0, // Set font size for title
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              Center(
                                child: Text(
                                  'Available At: ' + beerPubs!,
                                  style: TextStyle(
                                    fontSize:
                                        16.0, // Set font size for description
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              Center(
                                child: Text(
                                  beerDesc ?? '',
                                  style: TextStyle(
                                    fontSize:
                                        16.0, // Set font size for description
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              Center(
                                child: RatingBar.builder(
                                  initialRating: double.parse(beerVotesSum!),
                                  minRating: 1,
                                  direction: Axis.horizontal,
                                  allowHalfRating: true,
                                  itemCount: 5,
                                  itemPadding:
                                      EdgeInsets.symmetric(horizontal: 4.0),
                                  itemBuilder: (context, _) => Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  onRatingUpdate: (rating) {
                                    submitRating(rating);
                                  },
                                ),
                              ),
                            ],
                          ),
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
