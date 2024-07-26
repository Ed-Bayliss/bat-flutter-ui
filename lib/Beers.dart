import 'dart:io';
import 'dart:ui';
import 'package:burtonaletrail_app/BeerProfile.dart';
import 'package:burtonaletrail_app/QRScanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:burtonaletrail_app/Home.dart'; // Import for navigation
import 'package:burtonaletrail_app/WebViewPage.dart'; // Import for navigation

class BeersScreen extends StatefulWidget {
  @override
  _BeersScreenState createState() => _BeersScreenState();
}

class _BeersScreenState extends State<BeersScreen> {
  List<dynamic> beerData = [];
  List<dynamic> filteredBeerData = [];
  String? uuid;
  int _selectedIndex = 0; // Set initial index to Home
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchBeerData();
    searchController.addListener(() {
      filterBeers(searchController.text);
    });
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

      final response = await ioClient.get(
          Uri.parse('https://burtonaletrail.pawtul.com/beer_data/' + uuid));

      if (response.statusCode == 200) {
        setState(() {
          beerData = json.decode(response.body);
          filteredBeerData = beerData[0];
          print(filteredBeerData[1]['beerAvg']);
        });
      } else {
        throw Exception('Failed to load beer data');
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

  void filterBeers(String query) {
    final filtered = beerData[0].where((beer) {
      final beerName = beer['beerName'].toString().toLowerCase();
      final input = query.toLowerCase();
      return beerName.contains(input);
    }).toList();

    setState(() {
      filteredBeerData = filtered;
    });
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
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Beers',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                filteredBeerData.isEmpty
                    ? CircularProgressIndicator()
                    : Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.zero, // Remove padding
                          itemCount: filteredBeerData.length,
                          itemBuilder: (context, index) {
                            final item = filteredBeerData[index];
                            return Container(
                              padding: EdgeInsets.symmetric(
                                  vertical:
                                      10.0), // Adjust padding to make rows thinner
                              child: InkWell(
                                onTap: () {
                                  // Handle the tap event here
                                  // For example, you can navigate to a details page
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BeerProfileScreen(
                                          beerId: '${item['beerId']}'),
                                    ),
                                  );
                                },
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 0), // Adjust content padding
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item['beerName']}',
                                        style: TextStyle(
                                          fontSize:
                                              16.0, // Set font size for title
                                          color: item['beerVoted'] == 'voted'
                                              ? const Color.fromARGB(
                                                  255, 2, 119, 6)
                                              : Colors
                                                  .black, // Conditional text color
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Total Stars Given: ${item['beerVotesSum']}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: RatingBar.builder(
                                    initialRating:
                                        double.parse(item['beerAvg']),
                                    minRating: 1,
                                    direction: Axis.horizontal,
                                    allowHalfRating: true,
                                    itemCount: 5,
                                    itemSize:
                                        20.0, // Change this value to make stars smaller
                                    itemPadding:
                                        EdgeInsets.symmetric(horizontal: 4.0),
                                    itemBuilder: (context, _) => Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                    onRatingUpdate: (rating) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              BeerProfileScreen(
                                                  beerId: '${item['beerId']}'),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                SizedBox(height: 60),
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
