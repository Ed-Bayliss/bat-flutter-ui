import 'package:burtonaletrail_app/AppColors.dart';
import 'package:burtonaletrail_app/Beers.dart';
import 'package:burtonaletrail_app/Home.dart';
import 'package:burtonaletrail_app/Leaderboard.dart';
import 'package:burtonaletrail_app/Pubs.dart';
import 'package:burtonaletrail_app/Settings.dart';
import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  const CustomBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed, // Show labels for all items
      selectedItemColor: AppColors.primaryColor,
      unselectedItemColor: AppColors.secondaryColor,

      selectedLabelStyle: const TextStyle(
        fontSize: 12, // Consistent font size
        color: Colors.grey, // Explicit grey color
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12, // Consistent font size
        color: Colors.grey, // Explicit grey color
      ),
      onTap: (index) {
        // Handle the navigation or actions based on the index of the tapped item
        switch (index) {
          case 0:
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (Route<dynamic> route) => false);
            break;
          case 1:
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => const LeaderboardScreen()),
                (Route<dynamic> route) => false);
            break;
          case 2:
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => PubsScreen()),
                (Route<dynamic> route) => false);
            break;
          case 3:
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => BeersScreen()),
                (Route<dynamic> route) => false);
            break;
          case 4:
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => SettingsScreen()),
                (Route<dynamic> route) => false);
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home, size: 24),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.leaderboard, size: 24),
          label: 'Leaderboards',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.business_outlined, size: 24), // Icon for 3D Scans
          label: 'Pubs',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_drink, size: 24),
          label: 'Beers',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings, size: 24),
          label: 'Settings',
        ),
      ],
    );
  }
}
