import 'dart:io';
import 'dart:ui';
import 'package:burtonaletrail_app/AppApi.dart';
import 'package:burtonaletrail_app/AppDrawer.dart';
import 'package:burtonaletrail_app/BeerProfile.dart';
import 'package:burtonaletrail_app/NavBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rive/rive.dart' as rive;

class BeersScreen extends StatefulWidget {
  final int startTabIndex;

  // Accept a parameter for the starting tab index (default is 0).
  BeersScreen({this.startTabIndex = 0});

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
  String _loadingString = 'Loading, please wait...';
  String? selectedFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex:
          widget.startTabIndex, // Use the passed-in starting tab index
    );
    _tabController.addListener(_handleTabSelection);
    _loadBeers();

    // Set the initial beer list based on the starting tab.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        if (_tabController.index == 1) {
          currentList =
              allBeers.where((beer) => beer['isfavourite'] == true).toList();
        } else {
          currentList = allBeers;
        }
        _filterBeers();
      });
    });
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
            allBeers = data
                .map((beer) => {
                      ...beer,
                      'isfavourite': beer['isfavourite'] ?? false,
                      'votes_avg':
                          double.tryParse(beer['votes_avg'].toString()) ?? 0.0,
                      'votes_sum': beer['votes_sum'] ?? 0,
                    })
                .toList();
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

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(beer['graphic'] ?? ''),
                  backgroundColor: Colors.grey.shade200,
                ),
                title: Text(
                  beer['beer_name'] ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${votesAvg.toStringAsFixed(2)} Average Rating ($votesSum votes)'),
                    Text(beer['tasting_notes'] ?? ''),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(
                    isFavourited ? Icons.favorite : Icons.favorite_border,
                    color: isFavourited ? Colors.red : Colors.grey,
                  ),
                  onPressed: () =>
                      _toggleFavourite(beer['beer_id'], isFavourited),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BeerProfileScreen(
                        beerId: beer['beer_id'],
                      ),
                    ),
                  );
                },
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beers'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Beers'),
            Tab(text: 'Favourites'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(25.0),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          searchText = value;
                          _filterBeers();
                        });
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 15.0),
                        hintText: 'Search Beers',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(20.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: DropdownButton<String>(
                      value: selectedFilter,
                      hint: const Text('Filter'),
                      onChanged: (value) {
                        setState(() {
                          selectedFilter = value;
                          _filterBeers();
                        });
                      },
                      items: [
                        DropdownMenuItem(
                          value: 'average_rating',
                          child: Text('Average Rating'),
                        ),
                        DropdownMenuItem(
                          value: 'total_votes',
                          child: Text('Total Votes'),
                        ),
                        DropdownMenuItem(
                          value: 'most_favourited',
                          child: Text('Most Favourited'),
                        ),
                      ],
                      icon: const Icon(Icons.filter_list),
                      underline: Container(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBeerList()),
        ],
      ),
      drawer: const AppDrawer(activeItem: 1),
      bottomNavigationBar: CustomBottomNavigationBar(),
    );
  }
}
