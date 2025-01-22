import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
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

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // AnimatedList keys
  late GlobalKey<AnimatedListState> _soloListKey;
  late GlobalKey<AnimatedListState> _teamListKey;

  // Periodic refresh
  late Timer _updateTimer;

  // SOLO
  List<Map<String, dynamic>> soloLeaderboard = [];
  List<Map<String, dynamic>> _oldSoloLeaderboard = [];

  // TEAM
  List<Map<String, dynamic>> teamLeaderboard = [];
  List<Map<String, dynamic>> _oldTeamLeaderboard = [];

  // We store each player's arrow/diff across refreshes here
  // Key = player name, Value = {'positionChange': x, 'pointsDiff': y}
  Map<String, Map<String, int>> _soloArrows = {};

  // For teams as well
  Map<String, Map<String, int>> _teamArrows = {};

  // User info
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize keys
    _soloListKey = GlobalKey<AnimatedListState>();
    _teamListKey = GlobalKey<AnimatedListState>();

    _loadOldLeaderboardsFromPrefs().then((_) {
      // Now do your normal calls
      _forceRender(); // or directly _fetchLeaderboardFromCache() etc.
    });

    // Start periodic updates
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _updateLeaderboard();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _forceRender() async {
    setState(() {
      _isLoading = true;
    });

    await _fetchLeaderboardFromCache();
    await _fetchUserData();

    _tabController.animateTo(1);
    await Future.delayed(
        const Duration(milliseconds: 500)); // Wait for 0.5 seconds
    _tabController.animateTo(0); // Switch back to "Solo Leaderboard"

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _updateTimer.cancel(); // Cancel the timer to prevent calls to setState
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // <-- IMPORTANT: Check if still mounted after the await
      if (!mounted) return;

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
    } catch (e) {
      // You can check mounted here if you want to do setState,
      // but a simple print/log doesn’t require setState anyway:
      debugPrint('Error fetching user data: $e');
    }
  }

  /// Returns true if oldList and newList are the same ignoring
  /// ephemeral fields (positionChange, pointsDiff).
  bool _leaderboardListsAreSame(
    List<Map<String, dynamic>> oldList,
    List<Map<String, dynamic>> newList,
  ) {
    if (oldList.length != newList.length) return false;

    for (int i = 0; i < oldList.length; i++) {
      final oldItem = Map<String, dynamic>.from(oldList[i]);
      final newItem = Map<String, dynamic>.from(newList[i]);

      oldItem.remove('positionChange');
      oldItem.remove('pointsDiff');
      newItem.remove('positionChange');
      newItem.remove('pointsDiff');

      if (jsonEncode(oldItem) != jsonEncode(newItem)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _fetchLeaderboardFromCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? soloData = prefs.getString('solo_leaderboard');
    String? teamData = prefs.getString('team_leaderboard');

    if (soloData != null && teamData != null) {
      setState(() {
        soloLeaderboard = List<Map<String, dynamic>>.from(jsonDecode(soloData));
        teamLeaderboard = List<Map<String, dynamic>>.from(jsonDecode(teamData));

        if (_oldSoloLeaderboard.isEmpty) {
          _oldSoloLeaderboard =
              List<Map<String, dynamic>>.from(soloLeaderboard);
        }
        if (_oldTeamLeaderboard.isEmpty) {
          _oldTeamLeaderboard =
              List<Map<String, dynamic>>.from(teamLeaderboard);
        }
        print("updated from cache");
        _applyStoredArrowsToLeaderboard();
      });
    }
  }

  Future<void> _fetchLeaderboardFromNetwork() async {
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
      Uri.parse(apiServerLeaderboards),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'access_token': accessToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Cache the new data
      await prefs.setString('solo_leaderboard', jsonEncode(data['solo']));
      await prefs.setString('team_leaderboard', jsonEncode(data['team']));

      setState(() {
        soloLeaderboard = List<Map<String, dynamic>>.from(data['solo']);
        teamLeaderboard = List<Map<String, dynamic>>.from(data['team']);

        // If old arrays are still empty, initialize them
        if (_oldSoloLeaderboard.isEmpty) {
          _oldSoloLeaderboard =
              List<Map<String, dynamic>>.from(soloLeaderboard);
        }
        if (_oldTeamLeaderboard.isEmpty) {
          _oldTeamLeaderboard =
              List<Map<String, dynamic>>.from(teamLeaderboard);
        }
        print("updated from api");
      });
    } else {
      debugPrint('Failed to load leaderboard. Status: ${response.statusCode}');
    }
  }

  Future<void> _saveOldLeaderboardsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Already saving old_solo_leaderboard and old_team_leaderboard
    await prefs.setString(
      'old_solo_leaderboard',
      jsonEncode(_oldSoloLeaderboard),
    );
    await prefs.setString(
      'old_team_leaderboard',
      jsonEncode(_oldTeamLeaderboard),
    );

    // NEW: Also save the arrow maps
    await prefs.setString('solo_arrows', jsonEncode(_soloArrows));
    await prefs.setString('team_arrows', jsonEncode(_teamArrows));
  }

  /// Compare old/new lists for both SOLO and TEAM, apply arrow/diff logic,
  /// then animate changes in the two AnimatedLists.
  Future<void> _updateLeaderboard() async {
    await _fetchLeaderboardFromNetwork();

    try {
      // Keep old copies
      var oldSolo = List<Map<String, dynamic>>.from(_oldSoloLeaderboard);
      var oldTeam = List<Map<String, dynamic>>.from(_oldTeamLeaderboard);

      // Fetch updated data from cache (which sets soloLeaderboard, teamLeaderboard)
      await _fetchLeaderboardFromCache();

      var newSolo = List<Map<String, dynamic>>.from(soloLeaderboard);
      var newTeam = List<Map<String, dynamic>>.from(teamLeaderboard);

      var soloSame = _leaderboardListsAreSame(oldSolo, newSolo);
      var teamSame = _leaderboardListsAreSame(oldTeam, newTeam);

      if (!soloSame) {
        _applyArrowsAndAnimateSolo(oldSolo, newSolo);
      }
      if (!teamSame) {
        _applyArrowsAndAnimateTeam(oldTeam, newTeam);
      }

      // ======= SAVE the updated _oldSoloLeaderboard & _oldTeamLeaderboard =======
      // (which now reflect the new data + arrow updates).
      await _saveOldLeaderboardsToPrefs();
    } catch (e) {
      debugPrint('Error updating leaderboard: $e');
    }
  }

  Future<void> _loadOldLeaderboardsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final oldSoloJson = prefs.getString('old_solo_leaderboard');
    final oldTeamJson = prefs.getString('old_team_leaderboard');
    final soloArrowsJson = prefs.getString('solo_arrows');
    final teamArrowsJson = prefs.getString('team_arrows');

    if (oldSoloJson != null) {
      _oldSoloLeaderboard =
          List<Map<String, dynamic>>.from(jsonDecode(oldSoloJson));
    }
    if (oldTeamJson != null) {
      _oldTeamLeaderboard =
          List<Map<String, dynamic>>.from(jsonDecode(oldTeamJson));
    }

    // NEW: Decode arrow maps (if they exist)
    if (soloArrowsJson != null) {
      final Map<String, dynamic> map =
          jsonDecode(soloArrowsJson) as Map<String, dynamic>;
      _soloArrows = map.map((key, value) => MapEntry(
            key,
            {
              'positionChange': value['positionChange'] ?? 0,
              'pointsDiff': value['pointsDiff'] ?? 0,
            },
          ));
    }
    if (teamArrowsJson != null) {
      final Map<String, dynamic> map =
          jsonDecode(teamArrowsJson) as Map<String, dynamic>;
      _teamArrows = map.map((key, value) => MapEntry(
            key,
            {
              'positionChange': value['positionChange'] ?? 0,
              'pointsDiff': value['pointsDiff'] ?? 0,
            },
          ));
    }
  }

  void _applyStoredArrowsToLeaderboard() {
    // Re-apply SOLO arrows
    for (final player in soloLeaderboard) {
      final name = player['name'];
      if (_soloArrows.containsKey(name)) {
        player['positionChange'] = _soloArrows[name]!['positionChange'];
        player['pointsDiff'] = _soloArrows[name]!['pointsDiff'];
      }
    }

    // Re-apply TEAM arrows
    for (final team in teamLeaderboard) {
      final name = team['name'];
      if (_teamArrows.containsKey(name)) {
        team['positionChange'] = _teamArrows[name]!['positionChange'];
        team['pointsDiff'] = _teamArrows[name]!['pointsDiff'];
      }
    }
  }

  // ------------------ SOLO Logic ------------------

  void _applyArrowsAndAnimateSolo(
    List<Map<String, dynamic>> oldSolo,
    List<Map<String, dynamic>> newSolo,
  ) {
    // Step A: For each new item, compute or reuse arrow/diff
    // We build a helper map from old data to get old rank & old points
    final oldMap = <String, Map<String, dynamic>>{};
    for (int i = 0; i < oldSolo.length; i++) {
      final p = oldSolo[i];
      oldMap[p['name']] = {
        'rank': i,
        'points': p['credits'] ?? 0,
      };
    }

    // For each new user in newSolo:
    for (int i = 0; i < newSolo.length; i++) {
      final p = newSolo[i];
      final name = p['name'];
      final newPoints = p['credits'] ?? 0;
      final newRank = i;

      // If user not in oldMap, brand new => set arrow/diff = 0
      if (!oldMap.containsKey(name)) {
        // brand new user
        _soloArrows[name] = {
          'positionChange': 0,
          'pointsDiff': 0,
        };
        p['positionChange'] = 0;
        p['pointsDiff'] = 0;
        continue;
      }

      final oldRank = oldMap[name]!['rank'] as int;
      final oldPoints = oldMap[name]!['points'] as int;

      final rankDiff = oldRank - newRank; // +ve => moved up, -ve => moved down
      final ptsDiff = newPoints - oldPoints;

      // If there's an existing arrow record for this name
      final oldArrow =
          _soloArrows[name] ?? {'positionChange': 0, 'pointsDiff': 0};

      // If rank and points are unchanged, keep the old arrow/diff
      if (rankDiff == 0 && ptsDiff == 0) {
        p['positionChange'] = oldArrow['positionChange'] ?? 0;
        p['pointsDiff'] = oldArrow['pointsDiff'] ?? 0;
      } else {
        // Fresh arrow/diff
        p['positionChange'] = rankDiff;
        p['pointsDiff'] = ptsDiff;
      }

      // Update the stored arrow info
      _soloArrows[name] = {
        'positionChange': p['positionChange'],
        'pointsDiff': p['pointsDiff'],
      };
    }

    // Step B: Animate changes in the AnimatedList

    // 1) Remove items that differ or no longer exist
    for (int i = _oldSoloLeaderboard.length - 1; i >= 0; i--) {
      // If new list is shorter, or if name/credits/image are different
      if (i >= newSolo.length ||
          !_itemsAreSameIgnoringArrows(_oldSoloLeaderboard[i], newSolo[i])) {
        final removedItem = _oldSoloLeaderboard[i];
        _soloListKey.currentState?.removeItem(
          i,
          (context, animation) =>
              _buildAnimatedSoloItem(removedItem, animation, i),
        );
        _oldSoloLeaderboard.removeAt(i);
      }
    }

    // 2) Insert or re-insert
    for (int i = 0; i < newSolo.length; i++) {
      if (i >= _oldSoloLeaderboard.length) {
        // Need to insert
        _oldSoloLeaderboard.insert(i, newSolo[i]);
        _soloListKey.currentState?.insertItem(i);
      } else if (!_itemsAreSameIgnoringArrows(
          _oldSoloLeaderboard[i], newSolo[i])) {
        // Remove old, then insert new
        final removedItem = _oldSoloLeaderboard[i];
        _soloListKey.currentState?.removeItem(
          i,
          (context, animation) =>
              _buildAnimatedSoloItem(removedItem, animation, i),
        );
        _oldSoloLeaderboard.removeAt(i);

        _oldSoloLeaderboard.insert(i, newSolo[i]);
        _soloListKey.currentState?.insertItem(i);
      } else {
        // They match ignoring arrow fields, but let's update arrow fields
        _oldSoloLeaderboard[i] = newSolo[i];
      }
    }
  }

  // ------------------ TEAM Logic ------------------

  void _applyArrowsAndAnimateTeam(
    List<Map<String, dynamic>> oldTeam,
    List<Map<String, dynamic>> newTeam,
  ) {
    // A: Compute or reuse arrow/diff
    final oldMap = <String, Map<String, dynamic>>{};
    for (int i = 0; i < oldTeam.length; i++) {
      final t = oldTeam[i];
      oldMap[t['name']] = {
        'rank': i,
        'points': t['credits'] ?? 0,
      };
    }

    for (int i = 0; i < newTeam.length; i++) {
      final t = newTeam[i];
      final name = t['name'];
      final newPoints = t['credits'] ?? 0;
      final newRank = i;

      if (!oldMap.containsKey(name)) {
        // brand new team
        _teamArrows[name] = {
          'positionChange': 0,
          'pointsDiff': 0,
        };
        t['positionChange'] = 0;
        t['pointsDiff'] = 0;
        continue;
      }

      final oldRank = oldMap[name]!['rank'] as int;
      final oldPoints = oldMap[name]!['points'] as int;

      final rankDiff = oldRank - newRank; // +ve => up, -ve => down
      final ptsDiff = newPoints - oldPoints;

      final oldArrow =
          _teamArrows[name] ?? {'positionChange': 0, 'pointsDiff': 0};

      if (rankDiff == 0 && ptsDiff == 0) {
        // Keep old arrow/diff
        t['positionChange'] = oldArrow['positionChange'] ?? 0;
        t['pointsDiff'] = oldArrow['pointsDiff'] ?? 0;
      } else {
        // new arrow/diff
        t['positionChange'] = rankDiff;
        t['pointsDiff'] = ptsDiff;
      }

      // Update store
      _teamArrows[name] = {
        'positionChange': t['positionChange'],
        'pointsDiff': t['pointsDiff'],
      };
    }

    // B: Animate changes
    for (int i = _oldTeamLeaderboard.length - 1; i >= 0; i--) {
      if (i >= newTeam.length ||
          !_itemsAreSameIgnoringArrows(_oldTeamLeaderboard[i], newTeam[i])) {
        final removedItem = _oldTeamLeaderboard[i];
        _teamListKey.currentState?.removeItem(
          i,
          (context, animation) =>
              _buildAnimatedTeamItem(removedItem, animation, i),
        );
        _oldTeamLeaderboard.removeAt(i);
      }
    }

    // Insert or re-insert
    for (int i = 0; i < newTeam.length; i++) {
      if (i >= _oldTeamLeaderboard.length) {
        _oldTeamLeaderboard.insert(i, newTeam[i]);
        _teamListKey.currentState?.insertItem(i);
      } else if (!_itemsAreSameIgnoringArrows(
          _oldTeamLeaderboard[i], newTeam[i])) {
        final removedItem = _oldTeamLeaderboard[i];
        _teamListKey.currentState?.removeItem(
          i,
          (context, animation) =>
              _buildAnimatedTeamItem(removedItem, animation, i),
        );
        _oldTeamLeaderboard.removeAt(i);

        _oldTeamLeaderboard.insert(i, newTeam[i]);
        _teamListKey.currentState?.insertItem(i);
      } else {
        _oldTeamLeaderboard[i] = newTeam[i];
      }
    }
  }

  /// Compare ignoring 'positionChange' and 'pointsDiff'.
  bool _itemsAreSameIgnoringArrows(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final copyA = Map<String, dynamic>.from(a);
    final copyB = Map<String, dynamic>.from(b);
    copyA.remove('positionChange');
    copyA.remove('pointsDiff');
    copyB.remove('positionChange');
    copyB.remove('pointsDiff');
    return jsonEncode(copyA) == jsonEncode(copyB);
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
                            Tab(text: 'Solo Leaderboard'),
                            Tab(text: 'Team Leaderboard'),
                          ],
                        ),
                        Center(
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
                            Tab(text: 'Solo Leaderboard'),
                            Tab(text: 'Team Leaderboard'),
                          ],
                        ),
                        SizedBox(
                          height: size.height * 0.8,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _soloLeaderboardWidget(),
                              _teamLeaderboardWidget(),
                            ],
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Leaderboards',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Who are the top performers?',
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

  // ------------------ SOLO UI ------------------
  Widget _soloLeaderboardWidget() {
    return AnimatedList(
      key: _soloListKey,
      initialItemCount: soloLeaderboard.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index, animation) {
        final player = soloLeaderboard[index];
        return _buildAnimatedSoloItem(player, animation, index);
      },
    );
  }

  Widget _buildAnimatedSoloItem(
    Map<String, dynamic> player,
    Animation<double> animation,
    int index,
  ) {
    final posChange = player['positionChange'] ?? 0;
    final ptsDiff = player['pointsDiff'] ?? 0;

    Uint8List? imageBytes;
    if (player['image'] != null &&
        player['image'] is String &&
        isValidBase64(player['image'])) {
      imageBytes = base64Decode(player['image']);
    }

    return SizeTransition(
      sizeFactor: animation,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // Position
            Text(
              '${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 16),
            // Player Avatar
            CircleAvatar(
              backgroundImage:
                  imageBytes != null ? MemoryImage(imageBytes) : null,
              child: imageBytes == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 16),
            // Player Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + arrow
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          player['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (posChange > 0) ...[
                        const Icon(Icons.arrow_drop_up, color: Colors.green),
                        Text(
                          '+$posChange',
                          style: const TextStyle(color: Colors.green),
                        ),
                        if (ptsDiff != 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(+${ptsDiff} pts)',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ] else if (posChange < 0) ...[
                        const Icon(Icons.arrow_drop_down, color: Colors.red),
                        Text(
                          '$posChange',
                          style: const TextStyle(color: Colors.red),
                        ),
                        if (ptsDiff != 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${ptsDiff > 0 ? '+' : ''}$ptsDiff pts',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ],
                    ],
                  ),
                  // Points
                  Text(
                    '${player['credits']} pts',
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------ TEAM UI ------------------
  Widget _teamLeaderboardWidget() {
    return AnimatedList(
      key: _teamListKey,
      initialItemCount: teamLeaderboard.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index, animation) {
        final team = teamLeaderboard[index];
        return _buildAnimatedTeamItem(team, animation, index);
      },
    );
  }

  Widget _buildAnimatedTeamItem(
    Map<String, dynamic> team,
    Animation<double> animation,
    int index,
  ) {
    final posChange = team['positionChange'] ?? 0;
    final ptsDiff = team['pointsDiff'] ?? 0;

    Uint8List? imageBytes;
    if (team['image'] != null &&
        team['image'] is String &&
        isValidBase64(team['image'])) {
      imageBytes = base64Decode(team['image']);
    }

    return SizeTransition(
      sizeFactor: animation,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // Position
            Text(
              '${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 16),
            // Team Avatar
            CircleAvatar(
              backgroundImage:
                  imageBytes != null ? MemoryImage(imageBytes) : null,
              child: imageBytes == null ? const Icon(Icons.group) : null,
            ),
            const SizedBox(width: 16),
            // Team Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Team name + arrow
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          team['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (posChange > 0) ...[
                        const Icon(Icons.arrow_drop_up, color: Colors.green),
                        Text(
                          '+$posChange',
                          style: const TextStyle(color: Colors.green),
                        ),
                        if (ptsDiff != 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(+${ptsDiff} pts)',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ] else if (posChange < 0) ...[
                        const Icon(Icons.arrow_drop_down, color: Colors.red),
                        Text(
                          '$posChange',
                          style: const TextStyle(color: Colors.red),
                        ),
                        if (ptsDiff != 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${ptsDiff > 0 ? '+' : ''}$ptsDiff pts',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ],
                    ],
                  ),
                  // Points
                  Text(
                    '${team['credits']} pts',
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
