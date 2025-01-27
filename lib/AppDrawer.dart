import 'dart:convert';
import 'package:burtonaletrail_app/Badges.dart';
import 'package:burtonaletrail_app/Beers.dart';
import 'package:burtonaletrail_app/DrawListItem.dart';
import 'package:burtonaletrail_app/Home.dart';
import 'package:burtonaletrail_app/Leaderboard.dart';
import 'package:burtonaletrail_app/Login.dart';
import 'package:burtonaletrail_app/Pubs.dart';
import 'package:burtonaletrail_app/QRScanner.dart';
import 'package:burtonaletrail_app/Settings.dart';
import 'package:burtonaletrail_app/TrophyCabinet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppDrawer extends StatefulWidget {
  final int activeItem;
  const AppDrawer({super.key, required this.activeItem});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  late Size size;
  String userName = "Guest";
  String userImage = "";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? "Guest";
      userImage = prefs.getString('userImage') ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    return Container(
      height: size.height,
      width: size.width * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(size.height * 0.025),
          bottomRight: Radius.circular(size.height * 0.025),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: _btnClose()),
                  Flexible(flex: 2, child: _profilePic()),
                ],
              ),
            ),
          ),
          Flexible(
            flex: 6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(child: _drawerList()),
              ],
            ),
          ),
          Expanded(
            child: DrawerListItem(
              onTap: () async {
                // Clear shared preferences
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                // Navigate to the LoginScreen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false, // Remove all previous routes
                );
              },
              tileIcon: '',
              tileText: 'Sign Out',
              isActive: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _btnClose() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Builder(
            builder: (context) => GestureDetector(
              onTap: () => Scaffold.of(context).closeDrawer(),
              child: const Icon(Icons.close),
            ),
          ),
        ),
      ],
    );
  }

  Widget _profilePic() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            Flexible(
              flex: 7,
              child: InkWell(
                onTap: () {
                  // Add functionality for profile picture tap
                },
                child: SizedBox(
                  height: 120,
                  width: 120,
                  child: CircleAvatar(
                    radius: 60, // Adjust radius as needed
                    backgroundImage: userImage != null
                        ? MemoryImage(
                            base64Decode(userImage)) // Decode Base64 to bytes
                        : null, // Use null if no image is available
                    child: userImage == null
                        ? const Icon(Icons.person, size: 60) // Fallback icon
                        : null,
                  ),
                ),
              ),
            ),
            _verticalSpace(size.height * 0.009),
            Text(
              userName, // Accessing the variable directly
              style: nameTextStyle(size),
            ),
          ],
        ),
      ],
    );
  }

  Widget _drawerList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DrawerListItem(
          onTap: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomeScreen()),
            (Route<dynamic> route) => false,
          ),
          tileIcon: 'assets/svgs/measureicon.svg',
          tileText: 'Home',
          isActive: widget.activeItem == 1,
        ),
        DrawerListItem(
          onTap: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
            (Route<dynamic> route) => false,
          ),
          tileIcon: 'assets/svgs/profileicon.svg',
          tileText: 'Leaderboards',
          isActive: widget.activeItem == 2,
        ),
        // _verticalSpace(size.height * 0.016),
        DrawerListItem(
          onTap: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) => const TrophyCabinetScreen()),
            (Route<dynamic> route) => false,
          ),
          tileIcon: 'assets/svgs/arrow_forward.svg',
          tileText: 'Trophy Cabinet',
          isActive: widget.activeItem == 7,
        ),
        // _verticalSpace(size.height * 0.016),
        DrawerListItem(
          onTap: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => QRScanner()),
            (Route<dynamic> route) => false,
          ),
          tileIcon: 'assets/svgs/membersicon.svg',
          tileText: 'Scan/Check In',
          isActive: widget.activeItem == 3,
        ),
        DrawerListItem(
          onTap: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => PubsScreen()),
            (Route<dynamic> route) => false,
          ),
          tileIcon: 'assets/svgs/membersicon.svg',
          tileText: 'Pubs',
          isActive: widget.activeItem == 3,
        ),
        // _verticalSpace(size.height * 0.016),
        DrawerListItem(
          onTap: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => BeersScreen()),
            (Route<dynamic> route) => false,
          ),
          tileIcon: 'assets/svgs/retailersicon.svg',
          tileText: 'Beers',
          isActive: widget.activeItem == 4,
        ),
        // _verticalSpace(size.height * 0.016),
        DrawerListItem(
          onTap: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => SettingsScreen()),
            (Route<dynamic> route) => false,
          ),
          tileIcon: 'assets/svgs/settingsicon.svg',
          tileText: 'Settings',
          isActive: widget.activeItem == 6,
        ),
      ],
    );
  }

  Widget _verticalSpace(double height) {
    return SizedBox(
      height: height,
    );
  }

  TextStyle nameTextStyle(Size size) {
    return GoogleFonts.inter(
      fontWeight: FontWeight.w600,
      color: const Color(0xFF000000),
      fontSize: size.height * 0.020,
    );
  }
}
