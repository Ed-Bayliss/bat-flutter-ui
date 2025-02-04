import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardCarousel extends StatefulWidget {
  final List<List<Map<String, dynamic>>> leaderboardGroups;
  final List<String> titles;
  final String currentUserName;
  final String currentUserImage;
  final int currentUserPoints;
  final String currentTeamName;

  const LeaderboardCarousel({
    Key? key,
    required this.leaderboardGroups,
    required this.titles,
    required this.currentUserName,
    required this.currentUserImage,
    required this.currentUserPoints,
    required this.currentTeamName,
  }) : super(key: key);

  @override
  State<LeaderboardCarousel> createState() => _LeaderboardCarouselState();
}

class _LeaderboardCarouselState extends State<LeaderboardCarousel> {
  // "Old" leaderboards loaded from SharedPreferences
  List<Map<String, dynamic>> _oldSoloLeaderboard = [];
  List<Map<String, dynamic>> _oldTeamLeaderboard = [];

  // Arrow maps for position change & points diff
  // Example structure: { 'username': {'positionChange': 1, 'pointsDiff': -3} }
  Map<String, Map<String, int>> _soloArrows = {};
  Map<String, Map<String, int>> _teamArrows = {};

  @override
  void initState() {
    super.initState();
    _loadOldLeaderboardsFromPrefs();
  }

  /// Loads old leaderboards and arrow data from SharedPreferences.
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

    // Once loaded, rebuild the widget
    setState(() {});
  }

  /// Utility to return color based on positive/negative/zero.
  Color _getDiffColor(int diff) {
    if (diff > 0) {
      return Colors.green;
    } else if (diff < 0) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  /// Utility to show sign (+/-) in the text
  String _formatDiff(int diff) {
    // e.g., +3 or -2 or 0
    return diff > 0 ? '+$diff' : diff.toString();
  }

  /// Builds one leaderboard container with the given title and data.
  /// Shows only the user plus one above and one below.
  Widget _buildLeaderboardSection(
    double screenWidth,
    String title,
    List<Map<String, dynamic>> leaderboardData,
  ) {
    final userIndex = leaderboardData.indexWhere(
      (entry) => entry['name'] == widget.currentUserName,
    );

    var displayedData = leaderboardData;

    if (userIndex != -1) {
      int start = userIndex - 1;
      int end = userIndex + 1;

      if (start < 0) start = 0;
      if (end >= leaderboardData.length) end = leaderboardData.length - 1;

      displayedData = leaderboardData.sublist(start, end + 1);
    }

    return Container(
      width: screenWidth - 45,
      height: 220,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: ListView.builder(
              itemCount: displayedData.length,
              itemBuilder: (context, index) {
                final entry = displayedData[index];
                final userName = entry['name'];

                int positionDiff = 0;
                int pointsDiff = 0;
                if (title.toLowerCase().contains('solo')) {
                  positionDiff = _soloArrows[userName]?['positionChange'] ?? 0;
                  pointsDiff = _soloArrows[userName]?['pointsDiff'] ?? 0;
                } else if (title.toLowerCase().contains('team')) {
                  positionDiff = _teamArrows[userName]?['positionChange'] ?? 0;
                  pointsDiff = _teamArrows[userName]?['pointsDiff'] ?? 0;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rank
                      Text(
                        entry['rank'].toString().padLeft(2, '0'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Avatar
                      CircleAvatar(
                        backgroundImage: (entry['avatar'] != null &&
                                entry['avatar'].isNotEmpty)
                            ? MemoryImage(base64Decode(entry['avatar']))
                            : null,
                        radius: 20,
                        child:
                            (entry['avatar'] == null || entry['avatar'].isEmpty)
                                ? const Icon(Icons.person)
                                : null,
                      ),
                      const SizedBox(width: 8),
                      // User information
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Name
                                Text(
                                  userName,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                // Position difference arrow
                                Row(
                                  children: [
                                    if (positionDiff > 0)
                                      const Icon(Icons.arrow_drop_up,
                                          color: Colors.green),
                                    if (positionDiff < 0)
                                      const Icon(Icons.arrow_drop_down,
                                          color: Colors.red),
                                    Text(
                                      _formatDiff(positionDiff),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getDiffColor(positionDiff),
                                      ),
                                    ),
                                    Text(" "),
                                    Text(
                                      _formatDiff(pointsDiff),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getDiffColor(pointsDiff),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Points
                            Row(
                              children: [
                                Text(
                                  '${entry['points']} pts',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 6),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Shown if the user is "No Team"
  Widget _buildNoTeamSection(double screenWidth) {
    return Container(
      width: screenWidth - 45,
      height: 220,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          "You are not in a team.",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(widget.leaderboardGroups.length, (index) {
          // If it's the Team Leaderboard and the user has "No Team"
          if (widget.titles[index] == "Team Leaderboard" &&
              widget.currentTeamName == "No Team") {
            return _buildNoTeamSection(screenWidth);
          }
          // Otherwise, build the normal leaderboard section (3-entries style)
          return _buildLeaderboardSection(
            screenWidth,
            widget.titles[index],
            widget.leaderboardGroups[index],
          );
        }),
      ),
    );
  }
}
