import 'dart:io';

import 'package:burtonaletrail_app/Badges.dart';
import 'package:burtonaletrail_app/Beers.dart';
import 'package:burtonaletrail_app/Leaderboard.dart';
import 'package:burtonaletrail_app/Pubs.dart';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'dart:async'; // Add this import for the Timer class
import 'QRScanner.dart';
import 'WebViewPage.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String domain = "https://burtonaletrail.pawtul.com/";
  String? email;
  String? password;
  String? uuid;
  int _selectedIndex = 0;
  String userName = '';
  String userPoints = '0';
  String userPosition = '0';
  bool _showDiscoLights = true; // Add this boolean flag to control the visibility of the overlay

  Timer? _discoTimer; // Add this Timer variable to manage the periodic timer
  Timer? _hideOverlayTimer; // Add this Timer variable to manage the overlay visibility timer

  @override
  void initState() {
    super.initState();
    _getCredentials();
    _fetchUserData();
    _startDiscoLights(); // Start the disco lights animation
  }

  void _getCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString('email');
      password = prefs.getString('password');
    });
  }

void _fetchUserData() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? uuid = prefs.getString('uuid');

  if (uuid != null) {
    bool trustSelfSigned = true;
    HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => trustSelfSigned;
    IOClient ioClient = IOClient(httpClient);

    final response = await ioClient.get(Uri.parse('https://burtonaletrail.pawtul.com/home_screen/' + uuid));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data[0]);
      setState(() {
        userName = data[0]['userName'] ?? '';
        userPoints = data[0]['userPoints'] ?? '0';
        userPosition = data[0]['userPosition'] ?? '0';
      });
    } else {
      // Handle the error appropriately
      print('Failed to load user data');
    }
  } else {
    throw Exception('UUID not found');
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

  final List<Gradient> gradients = [
    LinearGradient(
      colors: [Colors.pink, Colors.orange, Colors.yellow],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Colors.blue, Colors.purple, Colors.red],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Colors.green, Colors.teal, Colors.blue],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Add more gradients as desired
  ];

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

  Color _color1 = Colors.transparent;
  Color _color2 = Colors.transparent;
  Color _color3 = Colors.transparent;
  Color _color4 = Colors.transparent;

  void _startDiscoLights() {
    _discoTimer = Timer.periodic(Duration(milliseconds: 500), (Timer timer) {
      setState(() {
        _color1 = _getRandomColor();
        _color2 = _getRandomColor();
        _color3 = _getRandomColor();
        _color4 = _getRandomColor();
      });
    });

    // Start a timer to hide the overlay after 4 seconds
    _hideOverlayTimer = Timer(Duration(seconds: 60), () {
      setState(() {
        _showDiscoLights = false; // Hide the overlay
        _discoTimer?.cancel(); // Cancel the periodic timer
      });
    });
  }

  Color _getRandomColor() {
    final colors = [
      Colors.red.withOpacity(0.1),
      Colors.green.withOpacity(0.1),
      Colors.blue.withOpacity(0.1),
      Colors.yellow.withOpacity(0.1),
      Colors.purple.withOpacity(0.1),
      Colors.orange.withOpacity(0.1),
    ];
    colors.shuffle();
    return colors.first;
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
              'assets/images/backdrop.jpg', // Path to your background image
              fit: BoxFit.cover, // Makes the image cover the entire screen
            ),
          ),
          // Foreground content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                Center(
                  child: Image.asset(
                    'assets/app_logo.png', // Path to your asset image
                    height: 200,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'HEY $userName 👋',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 1),
                Text(
                  'You have $userPoints points\nYou are $position$positionSuffix on the scoreboard',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildFeatureCard(
                        'Scores',
                        '',
                        '',
                        gradients,
                        1,
                        Icons.leaderboard,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => LeaderboardScreen()),
                          );
                        },
                      ),
                      _buildFeatureCard(
                        'Check In',
                        '',
                        '',
                        gradients,
                        2,
                        Icons.qr_code_scanner,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => QRScanner()),
                          );
                        },
                      ),
                      _buildFeatureCard(
                        'Pubs',
                        '',
                        '',
                        gradients,
                        3,
                        Icons.roofing,
                        onTap: () {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(builder: (context) => WebViewPage(
                          //       url: domain + 'redirect',
                          //       email: email ?? '',
                          //       password: password ?? '',
                          //       new_url: 'pubs'
                          //   )),
                          // );
                           Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => PubsScreen()),
                          );
                        },
                      ),
                      _buildFeatureCard(
                        'Beers',
                        '',
                        '',
                        gradients,
                        1,
                        Icons.sports_bar,
                        onTap: () {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(builder: (context) => WebViewPage(
                          //       url: domain + 'redirect',
                          //       email: email ?? '',
                          //       password: password ?? '',
                          //       new_url: 'ratings'
                          //   )),
                          // );
                           Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => BeersScreen()),
                          );
                        },
                      ),
                      _buildFeatureCard(
                        'Badges',
                        '',
                        '',
                        gradients,
                        2,
                        Icons.badge,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => BadgesScreen()),
                          );
},
),
_buildFeatureCard(
'Logout',
'',
'',
gradients,
3,
Icons.logout,
onTap: () {
Navigator.push(
context,
MaterialPageRoute(builder: (context) => WebViewPage(
url: domain + 'redirect',
email: email ?? '',
password: password ?? '',
new_url: 'logout'
)),
);
},
),
],
),
),
],
),
),
// Disco Lights Animation
if (_showDiscoLights)
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true, // This makes the overlay non-interactive
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: Container(color: _color1)),
                      Expanded(child: Container(color: _color2)),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: Container(color: _color3)),
                      Expanded(child: Container(color: _color4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
items: const [
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
selectedItemColor: Color.fromARGB(255, 255, 225, 0),
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

Widget _buildFeatureCard(
  String title, 
  String subtitle, 
  String? description, 
  List gradients, 
  int index, 
  IconData icon, // Added icon parameter
  {VoidCallback? onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradients[index % gradients.length],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'FunkyFont', // Use a funky 70's font here
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontFamily: 'FunkyFont',
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Center(
                    child: Icon(
                      icon, // Use the passed icon
                      size: 40,
                      color: Colors.white, // Set color to white for visibility
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

@override
void dispose() {
  _discoTimer?.cancel();
  _hideOverlayTimer?.cancel();
  super.dispose();
}
}