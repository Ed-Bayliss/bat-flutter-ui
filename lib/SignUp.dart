import 'package:burtonaletrail_app/Home.dart';
import 'package:burtonaletrail_app/Login.dart';
import 'package:burtonaletrail_app/PasswordReset.dart';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'dart:convert'; // For JSON encoding
import 'dart:io';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart'; // For random selection

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController codeController = TextEditingController();
  bool showCodeField = false;

  final List<String> sentences = [
    "Get your groove on with Burton Ale Trail!",
    "Disco and drafts, a match made in heaven!",
    "Boogie down and bottoms up!",
    "Stayin' alive with our special ale offers!",
    "Saturday night fever? Cure it with a pint!",
    "Dance the night away with a cold ale in hand!",
    "Cheers to disco days and ale nights!",
    "Find your boogie pub today!",
    "Shake your groove thing, sip your brew thing!",
    "Disco inferno meets ale oasis!"
  ];

  String getRandomSentence() {
    final random = Random();
    return sentences[random.nextInt(sentences.length)];
  }

  void SignupPost() async {
    String firstname = firstnameController.text;
    String surname = surnameController.text;
    String mobile = mobileController.text;

    String domain = "https://burtonaletrail.pawtul.com/";
    String url = domain + 'signup_app';

    Map<String, String> body = {
      'firstname': firstname,
      'surname': surname,
      'mobile': mobile,
      'pushSubscriptionId': 'null'
    };

    try {
      bool trustSelfSigned = true;
      HttpClient httpClient = new HttpClient()
        ..badCertificateCallback =
            ((X509Certificate cert, String host, int port) => trustSelfSigned);
      IOClient ioClient = new IOClient(httpClient);
      var response = await ioClient.post(Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body));

      if (response.statusCode == 200) {
        print('Request successful: ${response.body}');
        setState(() {
          showCodeField = true;
        });
      } else if (response.statusCode == 600) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('You already have an account. Please reset password.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PasswordResetScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signup Failed'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error during POST request: $e');
    }
  }

  Future<void> _saveLoginDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', mobileController.text);
    await prefs.setString('password', codeController.text);

    // Navigate to the login page after saving the details
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void submitCode() async {
    String code = codeController.text;
    String domain = "https://burtonaletrail.pawtul.com/";

    String url = domain + 'signup_verify';

    Map<String, String> body = {'code': code, 'mobile': mobileController.text};

    try {
      bool trustSelfSigned = true;
      HttpClient httpClient = new HttpClient()
        ..badCertificateCallback =
            ((X509Certificate cert, String host, int port) => trustSelfSigned);
      IOClient ioClient = new IOClient(httpClient);
      var response = await ioClient.post(Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Code verified successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        _saveLoginDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Code verification failed'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error during POST request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/backdrop.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Foreground content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/app_logo.png',
                  height: 200,
                ),
                if (!showCodeField) ...[
                  SizedBox(height: 20),
                  TextField(
                    controller: firstnameController,
                    decoration: InputDecoration(
                      labelText: 'Firstname',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: surnameController,
                    decoration: InputDecoration(
                      labelText: 'Surname',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: mobileController,
                    decoration: InputDecoration(
                      labelText: 'Mobile Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    autofillHints: [AutofillHints.telephoneNumber],
                  ),
                  // SizedBox(height: 20),
                  // TextField(
                  //   controller: passwordController,
                  //   decoration: InputDecoration(
                  //     labelText: 'Password',
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(8.0),
                  //     ),
                  //   ),
                  //   obscureText: true,
                  //   autofillHints: [AutofillHints.password],
                  // ),
                  // SizedBox(height: 20),
                  // TextField(
                  //   controller: confirmPasswordController,
                  //   decoration: InputDecoration(
                  //     labelText: 'Confirm Password',
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(8.0),
                  //     ),
                  //   ),
                  //   obscureText: true,
                  //   autofillHints: [AutofillHints.password],
                  // ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: SignupPost,
                    child: Text('Sign Up'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 60),
                      backgroundColor: Colors.yellow,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: Text(
                      'Already have an account? Login',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
                if (showCodeField) ...[
                  TextField(
                    controller: codeController,
                    decoration: InputDecoration(
                      labelText: 'Enter 6-digit code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: submitCode,
                    child: Text('Submit Code'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 60),
                      backgroundColor: Colors.yellow,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
