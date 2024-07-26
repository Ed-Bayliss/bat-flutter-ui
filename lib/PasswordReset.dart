import 'package:burtonaletrail_app/Login.dart';
import 'package:burtonaletrail_app/SignUp.dart';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordResetScreen extends StatefulWidget {
  @override
  _PasswordResetScreenState createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
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

  bool showCodeField = false;

  @override
  void initState() {
    super.initState();
  }

  void requestPasswordReset() async {
    String mobile = mobileController.text;
    String domain = "https://burtonaletrail.pawtul.com/";
    String url = domain + 'reset_request';

    Map<String, String> body = {
      'mobile': mobile,
    };

    try {
      bool trustSelfSigned = true;
      HttpClient httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => trustSelfSigned;
      IOClient ioClient = IOClient(httpClient);
      var response = await ioClient.post(Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Code sent to your mobile'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        setState(() {
          showCodeField = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('We didn\'t find an account. Please Sign Up.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SignupScreen()),
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
    String mobile = mobileController.text;
    String domain = "https://burtonaletrail.pawtul.com/";
    String url = domain + 'verify_reset_code';

    Map<String, String> body = {
      'mobile': mobile,
      'code': code,
    };

    try {
      bool trustSelfSigned = true;
      HttpClient httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => trustSelfSigned;
      IOClient ioClient = IOClient(httpClient);
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
        // Navigate to password reset form or any other action
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid code'),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/marvin.png',
                      height: 150,
                    ),
                    SizedBox(width: 20),
                  ],
                ),
                SizedBox(height: 20),
                if (!showCodeField) ...[
                  TextField(
                    controller: mobileController,
                    decoration: InputDecoration(
                      labelText: 'Mobile',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    autofillHints: [AutofillHints.telephoneNumber],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: requestPasswordReset,
                    child: Text('Request Code'),
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
                if (!showCodeField) ...[],
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
                    'Already have an account? Login here.',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
