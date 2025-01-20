import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:burtonaletrail_app/AppApi.dart';
import 'package:burtonaletrail_app/AppDrawer.dart';
import 'package:burtonaletrail_app/AppMenuButton.dart';
import 'package:burtonaletrail_app/LeaderboardWidget.dart';
import 'package:burtonaletrail_app/NavBar.dart';
import 'package:burtonaletrail_app/ProfilePage.dart';
import 'package:burtonaletrail_app/Sponsers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/io_client.dart';
import 'package:rive/rive.dart' as rive;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = '';
  String userPoints = '0';
  String userPosition = '0';
  String userSupport = 'off';
  String userImage = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load locally saved user data
    setState(() {
      userName = prefs.getString('userName') ?? '';
      userPoints = prefs.getString('userPoints') ?? '0';
      userPosition = prefs.getString('userPosition') ?? '0';
      userSupport = prefs.getString('userSupport') ?? 'off';
      userImage = prefs.getString('userImage') ?? '';
    });

    // Attempt to fetch updated data from the server
    String? accessToken = prefs.getString('access_token');

    if (accessToken != null) {
      bool trustSelfSigned = true;
      HttpClient httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => trustSelfSigned;
      IOClient ioClient = IOClient(httpClient);

      try {
        final response = await ioClient.post(
          Uri.parse(apiServerProfile),
          headers: {
            'Content-Type': 'application/json', // Specify JSON content type
          },
          body: jsonEncode({
            'access_token': accessToken, // Convert body to JSON string
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // Safely retrieve user and leaderboard data
          setState(() {
            userName = data['userName']?.toString() ?? userName;
            userPoints = data['userPoints']?.toString() ?? userPoints;
            userPosition = data['userPosition']?.toString() ?? userPosition;
            userSupport = data['userSupport']?.toString() ?? userSupport;
            userImage = data['userImage']?.toString() ?? userImage;

            // Save user data locally
            prefs.setString('userName', userName);
            prefs.setString('userPoints', userPoints);
            prefs.setString('userPosition', userPosition);
            prefs.setString('userSupport', userSupport);
            prefs.setString('userImage', userImage);

            // Save leaderboard data
            if (data['soloLeaderboardData'] != null) {
              prefs.setString('soloLeaderboardData',
                  jsonEncode(data['soloLeaderboardData']));
            }
            if (data['teamLeaderboardData'] != null) {
              prefs.setString('teamLeaderboardData',
                  jsonEncode(data['teamLeaderboardData']));
            }
          });
        } else {
          print(
              'Failed to load user data. Status code: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    } else {
      throw Exception('Access token not found');
    }
  }

  Future<List<Map<String, dynamic>>> _getsoloLeaderboardData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? leaderboardJson = prefs.getString('soloLeaderboardData');
    if (leaderboardJson != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(leaderboardJson));
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _getteamLeaderboardData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? leaderboardJson = prefs.getString('teamLeaderboardData');
    if (leaderboardJson != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(leaderboardJson));
    }
    return [];
  }

  Future<List<List<Map<String, dynamic>>>> _getLeaderboardGroups() async {
    try {
      // Fetch solo leaderboard data
      List<Map<String, dynamic>> soloLeaderboardData =
          await _getsoloLeaderboardData();

      // Fetch team leaderboard data
      List<Map<String, dynamic>> teamLeaderboardData =
          await _getteamLeaderboardData();

      // Combine into groups
      return [
        soloLeaderboardData, // Group 1: Solo leaderboard
        teamLeaderboardData, // Group 2: Team leaderboard
      ];
    } catch (e) {
      throw Exception('Failed to fetch leaderboard groups: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Background image positioned and scaled
          Positioned(
            width: MediaQuery.of(context).size.width * 1.7,
            bottom: 100,
            left: 100,
            child: Image.asset('assets/Backgrounds/Spline.png'),
          ),
          // Blurred background filter
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 10),
            ),
          ),
          // Rive animation
          const rive.RiveAnimation.asset('assets/RiveAssets/shapes.riv'),
          // Another layer of blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 10),
              child: const SizedBox(),
            ),
          ),
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(),
                    const SpecialOfferCarousel(),
                    FutureBuilder<List<List<Map<String, dynamic>>>>(
                      future:
                          _getLeaderboardGroups(), // Fetch leaderboard groups
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator(); // Loading state
                        } else if (snapshot.hasError) {
                          return Text(
                              'Error: ${snapshot.error}'); // Error state
                        } else if (snapshot.hasData) {
                          // Pass the fetched leaderboard groups to the LeaderboardCarousel
                          return LeaderboardCarousel(
                            leaderboardGroups: snapshot.data!,
                            currentUserName: userName,
                            currentUserImage: userImage,
                            currentUserPoints: int.parse(userPoints),
                          );
                        } else {
                          return const Text('No leaderboard data available');
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFavouritesSection(),
                    const SizedBox(height: 16),
                    _buildFindPubsSection(),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(activeItem: 1),
      bottomNavigationBar: CustomBottomNavigationBar(),
    );
  }

  String getGreeting() {
    var hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning 👋';
    } else if (hour < 17) {
      return 'Good Afternoon 👋';
    } else {
      return 'Good Evening 👋';
    }
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16), // Adjust vertical spacing as needed
        Row(
          children: [
            // AppMenuButton (burger menu)
            Builder(
              builder: (context) {
                return AppMenuButton(
                  onTap: () => Scaffold.of(context).openDrawer(),
                );
              },
            ),
            const SizedBox(width: 10),
            // Greeting texts (Good Morning and user name)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getGreeting(),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.normal),
                ),
                const SizedBox(height: 4),
                Text(
                  userName.isNotEmpty ? userName : 'Loading...',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                )
              ],
            ),
            const Spacer(),
            // User profile image
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
              child: CircleAvatar(
                backgroundImage: (userImage != null && isValidBase64(userImage))
                    ? MemoryImage(
                        base64Decode(userImage)) // Decode Base64 to bytes
                    : null, // Default to null if no valid image is available
                child: (userImage == null || !isValidBase64(userImage))
                    ? Icon(Icons
                        .person) // Fallback icon if userImage is null or invalid
                    : null,
              ),
            ),
            const SizedBox(width: 20),
          ],
        ),
      ],
    );
  }

  bool isValidBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return false;
    }

    try {
      final decodedBytes = base64Decode(base64String);
      return decodedBytes.isNotEmpty; // Check if decoding produces valid data
    } catch (e) {
      return false; // If decoding fails, it's not a valid Base64 string
    }
  }

  Widget _buildLeaderboards({
    required String userName,
    required String userImage,
    required int userPoints,
    required List<Map<String, dynamic>> soloLeaderboardData,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(blurRadius: 10, color: Colors.grey.shade200),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Leaderboards",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Solo Players',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Leaderboard List
          Column(
            children: soloLeaderboardData.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Rank and Avatar
                    Row(
                      children: [
                        Text(
                          entry['rank'].toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundImage: entry['avatar'] != null &&
                                  entry['avatar'].isNotEmpty
                              ? MemoryImage(base64Decode(entry['avatar']))
                              : null,
                          child:
                              entry['avatar'] == null || entry['avatar'].isEmpty
                                  ? const Icon(Icons.person) // Fallback icon
                                  : null,
                          radius: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry['name'],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    // Points and Change Indicator
                    Row(
                      children: [
                        Text(
                          '${entry['points']} pts',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry['change'] > 0
                              ? '+${entry['change']}'
                              : '${entry['change']}',
                          style: TextStyle(
                            color:
                                entry['change'] > 0 ? Colors.green : Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Current User Highlight
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.brown, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "Your Rank:",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // CircleAvatar(
                    //   backgroundImage: userImage.isNotEmpty
                    //       ? MemoryImage(base64Decode(userImage))
                    //       : null,
                    //   child: userImage.isEmpty
                    //       ? const Icon(Icons.person) // Fallback icon
                    //       : null,
                    //   radius: 20,
                    // ),
                    const SizedBox(width: 8),
                    Text(
                      userPosition,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                Text(
                  '$userPoints pts',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardButton(String text) {
    return ElevatedButton(
      onPressed: () {
        // Get.to(() => const Start3DMeasurement());
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEEEEEE),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      child: Text(
        text,
        style:
            const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFavouritesSection() {
    return Row(
      children: [
        Expanded(
          child: _buildFeatureCard(
            title: 'My Favourite Beers',
            icon: Icons.favorite,
            color: Colors.red,
            isActive: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildFeatureCard(
            title: 'View All Beers',
            icon: Icons.shopping_bag,
            color: Colors.pink,
            isActive: true,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    bool isActive = true,
  }) {
    return GestureDetector(
      onTap: isActive ? () {} : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [BoxShadow(blurRadius: 10, color: Colors.grey.shade200)]
              : [BoxShadow(blurRadius: 2, color: Colors.grey.shade400)],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isActive ? color : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.black : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFindPubsSection() {
    return GestureDetector(
      onTap: () {
        // Get.to(() => MapPage());
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF061237),
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: AssetImage('assets/images/map.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5),
                  BlendMode.darken,
                ),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Find Your Nearest Pub →",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Locate ales near you",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Quick and easy",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
