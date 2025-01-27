import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:burtonaletrail_app/LoadingScreen.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:burtonaletrail_app/AppApi.dart';
import 'package:burtonaletrail_app/AppColors.dart';
import 'package:burtonaletrail_app/AppDrawer.dart';
import 'package:burtonaletrail_app/AppMenuButton.dart';
import 'package:burtonaletrail_app/NavBar.dart';

class TrophyCabinetScreen extends StatefulWidget {
  const TrophyCabinetScreen({Key? key}) : super(key: key);

  @override
  _TrophyCabinetScreenState createState() => _TrophyCabinetScreenState();
}

class _TrophyCabinetScreenState extends State<TrophyCabinetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String userFirstname = '';
  String userSurname = '';
  String userMobile = '';
  String userEmail = '';
  String userName = '';
  String userPoints = '0';
  String userPosition = '0';
  String userSupport = 'off';
  String userImage = '';
  String userTeam = '';
  String userTeamImage = '';
  String userTeamMembers = '';
  String userTeamPoints = '';
  bool _isLoading = true;

  List<Map<String, dynamic>> unlockedBadges = [];
  List<Map<String, dynamic>> lockedBadges = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeState();
    _fetchBadges();
  }

  Future<void> _fetchBadges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');
      if (accessToken == null) {
        throw Exception('Access token not found');
      }

      bool trustSelfSigned = true;
      HttpClient httpClient = HttpClient()
        ..badCertificateCallback = (cert, host, port) => trustSelfSigned;
      IOClient ioClient = IOClient(httpClient);

      final response = await ioClient.post(
        Uri.parse(apiServerTrophys), // Ensure this is properly defined.
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'access_token': accessToken}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print(data);
        setState(() {
          unlockedBadges = data
              .where((badge) => badge['badge_unlocked'] == true)
              .map((badge) => {
                    'imageBase64': badge['badge_graphic'] ?? '',
                    'title': badge['badge_name'] ?? 'Unknown Badge',
                    'description': badge['badge_description'] ?? '',
                    'detailed': badge['badge_detailed_unlocked'] ?? '',
                  })
              .toList();

          lockedBadges = data
              .where((badge) => badge['badge_unlocked'] == false)
              .map((badge) => {
                    'imageBase64': badge['badge_graphic'] ?? '',
                    'title': badge['badge_name'] ?? 'Unknown Badge',
                    'description': badge['badge_description'] ?? '',
                    'detailed': badge['badge_detailed'] ?? '',
                  })
              .toList();
        });
      } else {
        debugPrint(
            'Failed to fetch badges. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching badges: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeState() async {
    // Create an instance of the Token class
    final token = Token();

    // Call the refresh method
    bool tokenRefreshed = await token.refresh();

    if (tokenRefreshed) {
      print('JWT token refreshed successfully');
      // Continue with additional initialization logic if necessary
    } else {
      print('Failed to refresh JWT token');
      // Handle the failure case, e.g., navigate to login or show an alert
    }

    // Fetch other user data or perform additional initialization here
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      userName = prefs.getString('userName') ?? '';
      userPoints = prefs.getString('userPoints') ?? '0';
      userPosition = prefs.getString('userPosition') ?? '0';
      userSupport = prefs.getString('userSupport') ?? 'off';
      userImage = prefs.getString('userImage') ?? '';
      userTeam = prefs.getString('userTeam') ?? '';
      userTeamImage = prefs.getString('userTeamImage') ?? '';
      userTeamMembers = prefs.getString('userTeamMembers') ?? '';
      userTeamPoints = prefs.getString('userTeamPoints') ?? '';
    });
  }

  Widget _buildBadge(String imageBase64, String title,
      {bool isDisabled = false,
      String? description = '',
      String? detailed = ''}) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          backgroundColor:
              Colors.transparent, // Make the background transparent
          context: context,
          isScrollControlled: true,
          builder: (BuildContext context) {
            return Align(
              alignment:
                  Alignment.bottomCenter, // Align it to the bottom center
              child: FractionallySizedBox(
                widthFactor: 0.9, // 90% of the screen width
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20), // Rounded corners for the modal
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isValidBase64(imageBase64))
                            Image.memory(
                              base64Decode(imageBase64),
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                            )
                          else
                            const Image(
                              image: AssetImage('assets/placeholder.png'),
                              width: 100,
                              height: 100,
                              fit: BoxFit.contain,
                            ),
                          const SizedBox(height: 16),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description ?? 'No description available.',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            detailed ?? '',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black87),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                  fontSize: 16, color: AppColors.primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              image: DecorationImage(
                image: isValidBase64(imageBase64)
                    ? MemoryImage(base64Decode(imageBase64))
                    : const AssetImage('assets/placeholder.png')
                        as ImageProvider,
                fit: BoxFit.contain,
                colorFilter: isDisabled
                    ? const ColorFilter.matrix(<double>[
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ])
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDisabled ? Colors.grey : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesGrid(List<Map<String, dynamic>> badges,
      {bool isDisabled = false}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: badges.length,
        itemBuilder: (context, index) {
          final badge = badges[index];
          return _buildBadge(
            badge['imageBase64'],
            badge['title'],
            description: badge['description'],
            detailed: badge['detailed'],
            isDisabled: isDisabled,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned(
            width: size.width * 1.7,
            bottom: 100,
            left: 100,
            child: Image.asset('assets/Backgrounds/Spline.png'),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 10),
            ),
          ),
          const rive.RiveAnimation.asset('assets/RiveAssets/shapes.riv'),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 10),
              child: const SizedBox(),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGreeting(),
                        TabBar(
                          controller: _tabController,
                          indicatorColor: AppColors.primaryColor,
                          labelColor: AppColors.primaryColor,
                          unselectedLabelColor: Colors.grey,
                          tabs: const [
                            Tab(text: 'Unlocked Awards'),
                            Tab(text: 'Available Awards'),
                          ],
                        ),
                        const Center(
                          child: LoadingScreen(
                            loadingText: "",
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGreeting(),
                        TabBar(
                          controller: _tabController,
                          indicatorColor: AppColors.primaryColor,
                          labelColor: AppColors.primaryColor,
                          unselectedLabelColor: Colors.grey,
                          tabs: const [
                            Tab(text: 'Unlocked Badges'),
                            Tab(text: 'Available Badges'),
                          ],
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 20.0, // Add padding at the top
                              // left: 16.0, // Add padding on the left
                              // right: 16.0, // Add padding on the right
                            ),
                            child: SizedBox(
                              height: size.height * 0.65,
                              width: size.width *
                                  0.9, // Ensure the width is 90% of the screen
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white, // White background
                                  borderRadius:
                                      BorderRadius.circular(20), // Curved edges
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                          0.1), // Optional shadow for depth
                                      spreadRadius: 2,
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal:
                                          16.0), // Add padding inside the box for text

                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      _buildBadgesGrid(unlockedBadges),
                                      _buildBadgesGrid(lockedBadges,
                                          isDisabled: true),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      drawer: const AppDrawer(activeItem: 1),
      bottomNavigationBar: CustomBottomNavigationBar(),
    );
  }

  /// Check if base64 is valid
  bool isValidBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return false;
    }
    try {
      base64Decode(base64String);
      return true;
    } catch (e) {
      return false;
    }
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Builder(
              builder: (context) {
                return AppMenuButton(
                  onTap: () => Scaffold.of(context).openDrawer(),
                );
              },
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trophy Cabinet',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'What awards are left to unlock?',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
            const Spacer(),
            InkWell(
              onTap: () {
                // Navigate to profile screen
              },
              child: CircleAvatar(
                backgroundImage:
                    (userImage.isNotEmpty && isValidBase64(userImage))
                        ? MemoryImage(base64Decode(userImage))
                        : null,
                child: (userImage.isEmpty || !isValidBase64(userImage))
                    ? const Icon(Icons.person)
                    : null,
              ),
            ),
            const SizedBox(width: 20),
          ],
        ),
      ],
    );
  }
}
