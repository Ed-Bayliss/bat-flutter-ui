import 'dart:io';
import 'dart:ui';
import 'package:burtonaletrail_app/AppApi.dart';
import 'package:burtonaletrail_app/AppColors.dart';
import 'package:burtonaletrail_app/AppDrawer.dart';
import 'package:burtonaletrail_app/AppMenuButton.dart';
import 'package:burtonaletrail_app/BeerProfile.dart';
import 'package:burtonaletrail_app/LoadingScreen.dart';
import 'package:burtonaletrail_app/NavBar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import 'package:rive/rive.dart' as rive;

class BeersScreen extends StatefulWidget {
  final int startTabIndex;

  const BeersScreen({super.key, this.startTabIndex = 0});

  @override
  _BeersScreenState createState() => _BeersScreenState();
}

class _BeersScreenState extends State<BeersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> allBeers = [];
  List<dynamic> favoriteBeers = [];
  List<dynamic> filteredBeers = [];
  List<dynamic> currentList = [];
  String searchText = "";
  bool _isLoading = false;
  String? selectedFilter;
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

  @override
  void initState() {
    super.initState();
    _initializeState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.startTabIndex,
    );
    _tabController.addListener(_handleTabSelection);
    _loadBeers();
  }

  void _handleTabSelection() {
    setState(() {
      currentList = _tabController.index == 0
          ? allBeers
          : allBeers.where((beer) => beer['isfavourite'] == true).toList();
      _filterBeers();
    });
  }

  Future<void> _loadBeers() async {
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
        Uri.parse(apiServerBeerList),
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
            allBeers = data.map((beer) {
              return {
                ...beer,
                'isfavourite': beer['isfavourite'] ?? false,
                'votes_avg':
                    double.tryParse(beer['votes_avg'].toString()) ?? 0.0,
                'votes_sum': beer['votes_sum'] ?? 0,
              };
            }).toList();
            currentList = _tabController.index == 1
                ? allBeers.where((beer) => beer['isfavourite'] == true).toList()
                : allBeers;
            _filterBeers();
          });
        } else {
          throw Exception('Unexpected data structure: Expected a list');
        }
      } else {
        throw Exception('Failed to load beer data');
      }
    } catch (e) {
      print('Error loading beers: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterBeers() {
    setState(() {
      filteredBeers = currentList.where((beer) {
        final nameMatches = beer['beer_name']
                ?.toLowerCase()
                .contains(searchText.toLowerCase()) ??
            false;
        return nameMatches;
      }).toList();

      if (selectedFilter == 'average_rating') {
        filteredBeers.sort((a, b) => b['votes_avg'].compareTo(a['votes_avg']));
      } else if (selectedFilter == 'total_votes') {
        filteredBeers.sort((a, b) => b['votes_sum'].compareTo(a['votes_sum']));
      } else if (selectedFilter == 'most_favourited') {
        filteredBeers.sort((a, b) =>
            (b['isfavourite'] ? 1 : 0).compareTo(a['isfavourite'] ? 1 : 0));
      }
    });
  }

  Widget _buildBeerList() {
    return filteredBeers.isEmpty
        ? const Center(child: Text('No beers found'))
        : ListView.separated(
            itemCount: filteredBeers.length,
            separatorBuilder: (context, index) => Divider(
              color: Colors.grey.shade300,
              thickness: 0.5,
              height: 1.0,
            ),
            itemBuilder: (context, index) {
              final beer = filteredBeers[index];
              final votesSum = beer['votes_sum'];
              final votesAvg = beer['votes_avg'];
              final isFavourited = beer['isfavourite'];

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
                      beer['beer_name'] ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  subtitle: Text(
                    '${votesAvg.toStringAsFixed(2)} Average Rating ($votesSum votes)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  trailing: SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: Icon(
                        isFavourited ? Icons.favorite : Icons.favorite_border,
                        color: isFavourited ? Colors.red : Colors.grey,
                        size: 24,
                      ),
                      onPressed: () {
                        _toggleFavourite(beer['beer_id'], beer['isfavourite']);
                      },
                    ),
                  ),
                ),
              );
            },
          );
  }

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
                Text(
                  'Rating: ${beer['votes_avg'].toStringAsFixed(2)} (${beer['votes_sum']} votes)',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
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
                    await _rateBeer(beer['beer_id'], rating);
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

  Future<void> _rateBeer(String beerId, double rating) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    if (accessToken != null) {
      try {
        final response = await http.post(
          Uri.parse(apiServerProfile), // Replace with your API endpoint
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'beerId': beerId,
            'rating': rating,
            'access_token': accessToken,
          }),
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to submit rating');
        }
      } catch (e) {
        print('Error submitting rating: $e');
      }
    }
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
                            Tab(text: 'Available Beers'),
                            Tab(text: 'Favourite Beers'),
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
                            Tab(text: 'Available Beers'),
                            Tab(text: 'Favourite Beers'),
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
                                    children: [_buildBeerList()],
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
                  'The Beer Menu',
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

  Future<void> _toggleFavourite(String beerId, bool isfavourite) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    if (accessToken != null) {
      try {
        final response = await http.post(
          Uri.parse(apiServerToggleFavourite),
          body: json.encode({
            'beerId': beerId,
            'favourite': !isfavourite,
            'access_token': accessToken
          }),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          setState(() {
            final index =
                allBeers.indexWhere((beer) => beer['beer_id'] == beerId);
            if (index != -1) {
              allBeers[index]['isfavourite'] = !isfavourite;
              if (_tabController.index == 1) {
                currentList = allBeers
                    .where((beer) => beer['isfavourite'] == true)
                    .toList();
                _filterBeers();
              }
            }
          });
        } else {
          throw Exception('Failed to toggle favourite status');
        }
      } catch (e) {
        print('Error toggling favourite: $e');
      }
    }
  }
}
