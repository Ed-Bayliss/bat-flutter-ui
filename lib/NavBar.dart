import 'package:burtonaletrail_app/AppColors.dart';
import 'package:burtonaletrail_app/Home.dart';
import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  CustomBottomNavigationBar();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed, // Show labels for all items
      selectedItemColor: AppColors.primaryColor,
      unselectedItemColor: AppColors.secondaryColor,

      selectedLabelStyle: TextStyle(
        fontSize: 12, // Consistent font size
        color: Colors.grey, // Explicit grey color
      ),
      unselectedLabelStyle: TextStyle(
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
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (Route<dynamic> route) => false);
            break;
          case 2:
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (Route<dynamic> route) => false);
            break;
          case 3:
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (Route<dynamic> route) => false);
            break;
          case 4:
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (Route<dynamic> route) => false);
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home, size: 24),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.leaderboard, size: 24),
          label: 'Votes',
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
