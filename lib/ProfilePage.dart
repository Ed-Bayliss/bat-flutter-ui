import 'dart:convert';
import 'dart:io';

import 'package:burtonaletrail_app/AppColors.dart';
import 'package:burtonaletrail_app/AppDrawer.dart';
import 'package:burtonaletrail_app/AppMenuButton.dart';
import 'package:burtonaletrail_app/NavBar.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

List<Map<String, dynamic>> items = []; // Example with an empty list

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Size size;
  late TabController _tabController;
  String userName = '';
  String userPoints = '0';
  String userPosition = '0';
  String userSupport = 'off';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? "Guest";
    });
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    return Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(
          activeItem: 2,
        ),
        body: _profileScreen(),
        bottomNavigationBar: CustomBottomNavigationBar());
  }

  Widget _profileScreen() {
    return SizedBox(
      height: size.height,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.03,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            _titleBar(),
            const SizedBox(height: 10),
            _profileTab(),
            const SizedBox(height: 10),
            // _addButton(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _titleBar() {
    final size = MediaQuery.of(context).size; // Access the screen size

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Builder(builder: (context) {
          return AppMenuButton(
            onTap: () => Scaffold.of(context).openDrawer(),
          );
        }),
        Text(
          'Profile',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(
          width: 30,
        ),
      ],
    );
  }

  Widget _profileTab() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            profileContainer(),
            const SizedBox(
              height: 10,
            ),
            const SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }

  Widget profileContainer() {
    return Container(
      width: size.width,
      decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFFEDF2F4)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit, // Use the Material "edit" icon
                    color: Colors.grey, // Optional: Customize color
                    size: 24.0, // Optional: Customize size
                  ),
                  onPressed: () async {
                    // Navigate to EditProfileScreen and refresh details
                    // await Get.to(EditProfileScreen(
                    //   userData: userDetails,
                    // ));
                    // await loadUserDetails();
                  },
                ),
              ],
            ),
            _profilePicture(),
            const SizedBox(
              height: 10,
            ),
            // _userNameAndEmail(),
          ],
        ),
      ),
    );
  }

  TextStyle nameTextStyle(Size size) {
    return GoogleFonts.inter(
      fontWeight: FontWeight.w600,
      color: const Color(0xFF000000),
      fontSize: size.height * 0.020,
    );
  }

  Widget _profilePicture() {
    return FutureBuilder<String?>(
      future: getUserImage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Show a loader while fetching
        }

        String? base64Image = snapshot.data;

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(width: 2, color: AppColors.primaryColor),
          ),
          child: ClipOval(
            child: base64Image != null && base64Image.isNotEmpty
                ? Image.memory(
                    base64Decode(base64Image),
                    fit: BoxFit.cover,
                    height: size.width * 0.5,
                    width: size.width * 0.5,
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person,
                          size: size.width * 0.2, color: Colors.grey),
                      Text(
                        'No Image',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Future<String?> getUserImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userImage'); // Retrieve the image string
  }

  void saveUserImage(String? base64Image) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (base64Image != null && base64Image.isNotEmpty) {
      await prefs.setString('userImage', base64Image); // Save the image string
    } else {
      await prefs.remove('userImage'); // Remove if no image is provided
    }
  }
}
