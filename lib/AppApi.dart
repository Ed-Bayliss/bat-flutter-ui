import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

String apiServer = 'https://burtonaletrail.pawtul.com'; //Server
// String apiServer = 'http://localhost:5000'; //iOS Simulator // Localhost
// String apiServer = 'http://192.168.1.54:5000'; //Real Device // Andriod Device

// AUTHENTICATION
String apiServerOTP = '$apiServer/api/auth/otp';
String apiServerOTPValidate = '$apiServer/api/auth/otp/validate';
String apiServerAuth = '$apiServer/api/auth/login';
String apiServerSponsers = '$apiServer/api/offers/all';

//PROFILE
String apiServerProfile = '$apiServer/api/profile';
String apiServerEditProfile = '$apiServer/api/profile/edit';
String apiServerGetUserRank = '$apiServer/api/rank/user';
String apiServerGetTeamRank = '$apiServer/api/rank/team';

String apiServerNotification = '$apiServer/api/notification/test';

String apiServerJWTValidate = '$apiServer/api/validate-token';

// BEERS
String apiServerBeerList = '$apiServer/api/beers/all';
String apiServerToggleFavourite = '$apiServer/api/beers/favourite';

//PUBS
String apiServerPubList = '$apiServer/api/pubs/all';
String apiServerPubBeerList = '$apiServer/api/pubs/beers';

//LEADERBOARD

String apiServerLeaderboards = '$apiServer/api/leaderboards/all';
String apiServerLeaderboardsTeamQuery =
    '$apiServer/api/leaderboards/team/query';

//TROPHIES
String apiServerTrophys = '$apiServer/api/trophycabinet/all';

class Token {
  Future<bool> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final refreshToken = prefs.getString('refresh_token');

    if (accessToken == null) {
      // No token found
      return false;
    }

    final url = Uri.parse(
        apiServerJWTValidate); // Replace with your actual server endpoint

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $accessToken', // Adjust if your server expects a different auth header
        },
        body: jsonEncode({
          'access_token': accessToken,
          'refresh_token': refreshToken,
          'push_token': OneSignal.User.pushSubscription.id.toString()
        }), // Adjust based on your server's expected payload
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['access_token'] != null) {
          final accessToken = jsonResponse['access_token'];
          final refreshToken = jsonResponse['refresh_token'];
          // Store the access token in shared preferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', accessToken);
          await prefs.setString('refresh_token', refreshToken);
        }
        return true;
      } else {
        // Token is invalid or other error
        print('Token validation failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      // Handle any errors during the HTTP request
      print('Error validating token: $e');
      return false;
    }
  }
}
