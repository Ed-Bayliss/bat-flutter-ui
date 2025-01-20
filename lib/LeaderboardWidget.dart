import 'dart:convert';
import 'package:flutter/material.dart';

class LeaderboardCarousel extends StatelessWidget {
  final List<List<Map<String, dynamic>>> leaderboardGroups;
  final String currentUserName;
  final String currentUserImage;
  final int currentUserPoints;

  const LeaderboardCarousel({
    Key? key,
    required this.leaderboardGroups,
    required this.currentUserName,
    required this.currentUserImage,
    required this.currentUserPoints,
  }) : super(key: key);

  Widget _buildLeaderboardSection(
      String title, List<Map<String, dynamic>> leaderboardData) {
    return Container(
      width: 350,
      height: 220, // Set a fixed width for horizontal scrolling
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
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 140, // Limit the height of the leaderboard list
            child: ListView.builder(
              itemCount: leaderboardData.length,
              itemBuilder: (context, index) {
                final entry = leaderboardData[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                            child: entry['avatar'] == null ||
                                    entry['avatar'].isEmpty
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
                      Text(
                        '${entry['points']} pts',
                        style: const TextStyle(fontSize: 16),
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

  @override
  Widget build(BuildContext context) {
    final List<String> titles = ["Solo Leaderboard", "Team Leaderboard"];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          leaderboardGroups.length,
          (index) => _buildLeaderboardSection(
            titles[index],
            leaderboardGroups[index],
          ),
        ),
      ),
    );
  }
}
