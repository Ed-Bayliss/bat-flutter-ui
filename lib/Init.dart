// lib/services/initialize_state.dart
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/io_client.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:burtonaletrail_app/AppApi.dart';
// Import your Token class (adjust the path as needed)

/// A simple model class to hold user data.
class UserData {
  final String userId;
  final String userName;
  final String userFirstname;
  final String userSurname;
  final String userMobile;
  final String userEmail;
  final String userPoints;
  final String userPosition;
  final String userSupport;
  final String userImage;
  final String userTeam;
  final String userTeamImage;
  final String userTeamMembers;
  final String userTeamPoints;
  final String userTeamAdmin;

  UserData({
    required this.userId,
    required this.userName,
    required this.userFirstname,
    required this.userSurname,
    required this.userMobile,
    required this.userEmail,
    required this.userPoints,
    required this.userPosition,
    required this.userSupport,
    required this.userImage,
    required this.userTeam,
    required this.userTeamImage,
    required this.userTeamMembers,
    required this.userTeamPoints,
    required this.userTeamAdmin,
  });
}

/// Refreshes the JWT token, loads local user data,
/// attempts to update it from the server, and returns [UserData].
Future<UserData?> initializeState() async {
  // Create an instance of your Token class.
  final token = Token();

  // Call the refresh method.
  bool tokenRefreshed = await token.refresh();

  if (tokenRefreshed) {
    print('JWT token refreshed successfully');
  } else {
    print('Failed to refresh JWT token');
  }

  // Load locally saved user data.
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String userId = prefs.getString('userId') ?? '';
  String userName = prefs.getString('userName') ?? '';
  String userFirstname = prefs.getString('userFirstname') ?? '';
  String userSurname = prefs.getString('userSurname') ?? '';
  String userMobile = prefs.getString('userMobile') ?? '';
  String userEmail = prefs.getString('userEmail') ?? '';
  String userPoints = prefs.getString('userPoints') ?? '0';
  String userPosition = prefs.getString('userPosition') ?? '0';
  String userSupport = prefs.getString('userSupport') ?? 'off';
  String userImage = prefs.getString('userImage') ?? '';
  String userTeam = prefs.getString('userTeam') ?? '';
  String userTeamImage = prefs.getString('userTeamImage') ?? '';
  String userTeamMembers = prefs.getString('userTeamMembers') ?? '';
  String userTeamPoints = prefs.getString('userTeamPoints') ?? '';
  String userTeamAdmin = prefs.getString('userTeamAdmin') ?? '';

  // Attempt to fetch updated data from the server.
  String? accessToken = prefs.getString('access_token');

  if (accessToken != null) {
    bool trustSelfSigned = true;
    HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => trustSelfSigned;
    IOClient ioClient = IOClient(httpClient);

    try {
      final response = await ioClient.post(
        Uri.parse(apiServerProfile),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'access_token': accessToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Update the user data with values from the server.
        userId = data['userId']?.toString() ?? userId;
        userFirstname = data['userFirstname']?.toString() ?? userFirstname;
        userSurname = data['userSurname']?.toString() ?? userSurname;
        userMobile = data['userMobile']?.toString() ?? userMobile;
        userEmail = data['userEmail']?.toString() ?? userEmail;
        userName = data['userName']?.toString() ?? userName;
        userPoints = data['userPoints']?.toString() ?? userPoints;
        userPosition = data['userPosition']?.toString() ?? userPosition;
        userSupport = data['userSupport']?.toString() ?? userSupport;
        userImage = data['userImage']?.toString() ?? userImage;
        userTeam = data['userTeam']?.toString() ?? userTeam;
        userTeamImage = data['userTeamImage']?.toString() ?? userTeamImage;
        userTeamMembers =
            data['userTeamMembers']?.toString() ?? userTeamMembers;
        userTeamPoints = data['userTeamPoints']?.toString() ?? userTeamPoints;
        userTeamAdmin = data['userTeamAdmin']?.toString() ?? userTeamAdmin;

        // Save updated user data locally.
        prefs.setString('userId', userId);
        prefs.setString('userName', userName);
        prefs.setString('userFirstname', userFirstname);
        prefs.setString('userSurname', userSurname);
        prefs.setString('userMobile', userMobile);
        prefs.setString('userEmail', userEmail);
        prefs.setString('userPoints', userPoints);
        prefs.setString('userPosition', userPosition);
        prefs.setString('userSupport', userSupport);
        prefs.setString('userImage', userImage);
        prefs.setString('userTeam', userTeam);
        prefs.setString('userTeamImage', userTeamImage);
        prefs.setString('userTeamMembers', userTeamMembers);
        prefs.setString('userTeamPoints', userTeamPoints);
        prefs.setString('userTeamAdmin', userTeamAdmin);
      } else {
        print('Failed to load user data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  } else {
    print('Access token not found');
    return null;
  }

  return UserData(
    userId: userId,
    userName: userName,
    userFirstname: userFirstname,
    userSurname: userSurname,
    userMobile: userMobile,
    userEmail: userEmail,
    userPoints: userPoints,
    userPosition: userPosition,
    userSupport: userSupport,
    userImage: userImage,
    userTeam: userTeam,
    userTeamImage: userTeamImage,
    userTeamMembers: userTeamMembers,
    userTeamPoints: userTeamPoints,
    userTeamAdmin: userTeamAdmin,
  );
}
