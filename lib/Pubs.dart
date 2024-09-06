import 'dart:io';
import 'dart:ui';
import 'package:burtonaletrail_app/PubProfile.dart';
import 'package:burtonaletrail_app/QRScanner.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:burtonaletrail_app/Home.dart'; // Import for navigation
import 'package:burtonaletrail_app/WebViewPage.dart'; // Import for navigation

class PubsScreen extends StatefulWidget {
  @override
  _PubsScreenState createState() => _PubsScreenState();
}

class _PubsScreenState extends State<PubsScreen> {
  List<dynamic> pubData = [];
  List<dynamic> filteredPubData = [];
  String? uuid;
  int _selectedIndex = 0; // Set initial index to Home
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPubData();
    searchController.addListener(() {
      filterPubs(searchController.text);
    });
  }

  Future<void> fetchPubData() async {
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

    final response = await ioClient
        .get(Uri.parse('https://burtonaletrail.pawtul.com/pub_data/' + uuid));

    if (response.statusCode == 200) {
      setState(() {
        pubData = json.decode(response.body);
        print(pubData);
        filteredPubData = pubData[0];
      });
    } else {
      throw Exception('Failed to load pub data');
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

  void filterPubs(String query) {
    final filtered = pubData[0].where((pub) {
      final pubName = pub['pubName'].toString().toLowerCase();
      final input = query.toLowerCase();
      return pubName.contains(input);
    }).toList();

    setState(() {
      filteredPubData = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
                    labelText: 'Search Pubs',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                filteredPubData.isEmpty
                    ? CircularProgressIndicator()
                    : Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.only(
                              bottom:
                                  bottomPadding), // Add padding to the bottom
                          itemCount: filteredPubData.length,
                          itemBuilder: (context, index) {
                            final item = filteredPubData[index];
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
                                        builder: (context) => PubProfileScreen(
                                            pubId: '${item['pubId']}'),
                                      ),
                                    );
                                  },
                                  child: ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 0),
                                    leading: Stack(
                                      children: [
                                        Container(
                                          width: 80.0,
                                          height: 80.0,
                                          child: ClipRect(
                                            child:
                                                item['pubAwarded'] == 'awarded'
                                                    ? ImageFiltered(
                                                        imageFilter:
                                                            ImageFilter.blur(
                                                                sigmaX: 2.0,
                                                                sigmaY: 2.0),
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  8.0), // Adjust the value to get the desired roundness
                                                          child: Image.asset(
                                                            '${item['pubLogo']}',
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      )
                                                    : ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                8.0), // Adjust the value to get the desired roundness
                                                        child: Image.asset(
                                                          '${item['pubLogo']}',
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                          ),
                                        ),
                                        if (item['pubAwarded'] == 'awarded')
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size:
                                                  32.0, // Adjust size as needed
                                            ),
                                          ),
                                      ],
                                    ),
                                    title: Text(
                                      item['pubName'],
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        color: item['pubAwarded'] == 'awarded'
                                            ? const Color.fromARGB(
                                                255, 2, 119, 6)
                                            : Colors.black,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${item['pubCheckIn']} check-ins',
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        color: item['pubAwarded'] == 'awarded'
                                            ? const Color.fromARGB(
                                                255, 2, 119, 6)
                                            : Colors.black,
                                      ),
                                    ),
                                  )),
                            );
                          },
                        ),
                      ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
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
