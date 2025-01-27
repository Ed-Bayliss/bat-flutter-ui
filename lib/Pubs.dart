import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:burtonaletrail_app/AppApi.dart';
import 'package:burtonaletrail_app/AppColors.dart';
import 'package:burtonaletrail_app/AppDrawer.dart';
import 'package:burtonaletrail_app/AppMenuButton.dart';
import 'package:burtonaletrail_app/LoadingScreen.dart';
import 'package:burtonaletrail_app/NavBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:rive/rive.dart' as rive;
import 'package:shared_preferences/shared_preferences.dart';

class PubsScreen extends StatefulWidget {
  const PubsScreen({super.key});

  @override
  _PubsScreenState createState() => _PubsScreenState();
}

class _PubsScreenState extends State<PubsScreen> {
  List<dynamic> allPubs = [];
  List<dynamic> filteredPubs = [];

  bool _isLoading = false;
  String searchText = "";

  // User Info
  String userName = '';
  String userPoints = '0';
  String userPosition = '0';
  String userSupport = 'off';
  String userImage = '';
  String userTeam = '';
  String userTeamImage = '';
  String userTeamMembers = '';
  String userTeamPoints = '';

  // Beers to display in bottom sheet for a selected pub
  List<Map<String, dynamic>> beers = [];

  @override
  void initState() {
    super.initState();
    _initializeState();
    _fetchPubs();
  }

  /// Fetch all pubs from the backend
  Future<void> _fetchPubs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    final HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    final IOClient ioClient = IOClient(httpClient);

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ioClient.post(
        Uri.parse(apiServerPubList),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'access_token': accessToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            allPubs = data;
            filteredPubs = allPubs;
          });
        } else {
          throw Exception('Unexpected data structure: Expected a list');
        }
      } else {
        throw Exception('Failed to load pub data');
      }
    } catch (e) {
      debugPrint('Error loading pubs: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Filter pubs by name if you want to add a search bar
  void _filterPubs() {
    setState(() {
      filteredPubs = allPubs.where((pub) {
        final nameMatches =
            pub['pub_name']?.toLowerCase().contains(searchText.toLowerCase()) ??
                false;
        return nameMatches;
      }).toList();
    });
  }

  /// Build the ListView of pubs
  Widget _buildPubList() {
    if (filteredPubs.isEmpty) {
      return const Center(child: Text('No pubs found'));
    }
    return ListView.separated(
      itemCount: filteredPubs.length,
      separatorBuilder: (context, index) => Divider(
        color: Colors.grey.shade300,
        thickness: 0.5,
        height: 1.0,
      ),
      itemBuilder: (context, index) {
        final pub = filteredPubs[index];

        return GestureDetector(
          onTap: () => _showPubDetails(context, pub),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: SizedBox(
              width: 60,
              height: 60,
              child: CircleAvatar(
                radius: 30,
                backgroundColor: pub['user_has_badge'] == true
                    ? AppColors.primaryColor
                    : Colors.grey.shade200,
                child: pub['user_has_badge'] == true
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 30,
                      )
                    : CircleAvatar(
                        radius: 30,
                        backgroundImage: AssetImage(pub['logo'] ?? ''),
                        backgroundColor: Colors.transparent,
                      ),
              ),
            ),
            title: Text(
              pub['name'] ?? '',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              pub['description'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  /// Build a list of beers for the selected pub
  Widget _buildBeerList() {
    if (beers.isEmpty) {
      return const Center(child: Text('No beers found'));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: beers.length,
      separatorBuilder: (context, index) => Divider(
        color: Colors.grey.shade300,
        thickness: 0.5,
        height: 1.0,
      ),
      itemBuilder: (context, index) {
        final beer = beers[index];
        // final votesSum = beer['votes_sum'];
        // final votesAvg = beer['votes_avg'];

        return GestureDetector(
          onTap: () => _showBeerDetails(context, beer),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: SizedBox(
              width: 60,
              height: 60,
              child: CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(beer['graphic'] ?? ''),
                backgroundColor: Colors.grey.shade200,
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                beer['name'] ?? '',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // subtitle: Text(
            //   '${votesAvg.toStringAsFixed(2)} Average Rating ($votesSum votes)',
            //   style: const TextStyle(
            //     fontSize: 14,
            //     color: Colors.grey,
            //   ),
            // ),
            // Removed the favorite icon
            trailing: null,
          ),
        );
      },
    );
  }

  /// Show pub details in a bottom sheet, plus the beer list
  Future<void> _showPubDetails(BuildContext context, dynamic pub) async {
    beers = [];

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
      Uri.parse(apiServerPubBeerList),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'access_token': accessToken,
        // If 'pub['id']' is an integer, use it directly.
        // If it's a string, parse it:
        // 'pub_id': int.parse(pub['id']),
        'pub_id': pub['id'],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // If it’s a List, parse into List<Map<String, dynamic>>
      if (data is List) {
        setState(() {
          beers = List<Map<String, dynamic>>.from(data);
        });
      } else {
        debugPrint('Expected a list at top-level, but got ${data.runtimeType}');
        beers = [];
      }
    } else {
      debugPrint(
        'Failed to get beer information. Status: ${response.statusCode}',
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9, // Opens at 70% of the screen height
          minChildSize: 0.3, // Minimum height is 30% of the screen
          maxChildSize: 0.9, // Maximum height is 90% of the screen
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Large circle avatar for pub image
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircleAvatar(
                        radius: 100,
                        backgroundImage: AssetImage(pub['logo'] ?? ''),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      pub['name'] ?? 'Pub Name',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pub['description'] ?? 'No description available.',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Beer list
                    _buildBeerList(),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Example "show beer details" method.
  /// Adjust this as needed (currently just shows a placeholder dialog).
  void _showBeerDetails(BuildContext context, dynamic beer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        double currentRating = beer['userRating']?.toDouble() ?? 0.0;

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                    width: 200,
                    height: 200,
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(beer['graphic'] ?? ''),
                      backgroundColor: Colors.grey.shade200,
                    )),
                Text(
                  beer['beer_name'] ?? 'Beer Name',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  beer['tasting_notes'] ?? 'No description available.',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Text(
                //   'Rating: ${beer['votes_avg'].toStringAsFixed(2)} (${beer['votes_sum']} votes)',
                //   style:
                //       const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                // ),
                const SizedBox(height: 16),
                const Text(
                  'Rate this beer:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                RatingBar.builder(
                  initialRating: currentRating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) async {
                    // Save the new rating
                    // await _rateBeer(beer['beer_id'], rating);
                    setState(() {
                      beer['userRating'] = rating;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Close',
                    style:
                        TextStyle(fontSize: 16, color: AppColors.primaryColor),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Initialize user data and refresh token
  Future<void> _initializeState() async {
    // Create an instance of the Token class
    final token = Token();

    // Call the refresh method
    bool tokenRefreshed = await token.refresh();

    if (tokenRefreshed) {
      debugPrint('JWT token refreshed successfully');
    } else {
      debugPrint('Failed to refresh JWT token');
    }

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

  /// Helper to check if a string is valid base64
  bool isValidBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return false;
    }
    try {
      base64Decode(base64String);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Build a greeting & top row with menu and user avatar
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
                  'The Pubs',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'There is something for everyone',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
            const Spacer(),
            InkWell(
              onTap: () {
                // Navigate to profile screen if needed
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBody: true,
      drawer: const AppDrawer(activeItem: 1),
      body: Stack(
        children: [
          // Background
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

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isLoading
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGreeting(),
                        const Center(
                          child: LoadingScreen(loadingText: ""),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGreeting(),
                        // Container for pub list
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: SizedBox(
                              height: size.height * 0.705,
                              width: size.width * 0.9,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      spreadRadius: 2,
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: _buildPubList(),
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
      bottomNavigationBar: CustomBottomNavigationBar(),
    );
  }
}
