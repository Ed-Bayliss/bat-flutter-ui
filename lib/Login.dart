import 'package:burtonaletrail_app/Home.dart';
import 'package:burtonaletrail_app/PasswordReset.dart';
import 'package:burtonaletrail_app/SignUp.dart';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'dart:convert'; // For JSON encoding
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math'; // For random selection

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
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

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
    String? password = prefs.getString('password');

    if (email != null && password != null) {
      emailController.text = email;
      passwordController.text = password;
      LoginPost();
    } else {
      if (emailController.text != '' && passwordController.text != '') {
        await prefs.setString('email', emailController.text);
        await prefs.setString('password', passwordController.text);
        LoginPost();
      }
    }
  }

  void LoginPost() async {
    String email = emailController.text;
    String password = passwordController.text;
    String domain = "https://burtonaletrail.pawtul.com/";

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('password', password);

    String url = domain + 'login_app';

    Map<String, String> body = {
      'email': email,
      'password': password,
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
        var responseBody = jsonDecode(response.body);

        String externalId = responseBody[0]['external_id'];
        await prefs.setString('uuid', externalId);

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Your mobile number, or password wasn\'t recognoised.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
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
                    // Container(
                    //   padding: EdgeInsets.all(8.0),
                    //   decoration: BoxDecoration(
                    //     color: Colors.white,
                    //     borderRadius: BorderRadius.circular(8.0),
                    //   ),
                    //   child: Text(
                    //     getRandomSentence(),
                    //     style: TextStyle(color: Colors.black),
                    //   ),
                    // ),
                  ],
                ),
                SizedBox(height: 20),
                TextField(
                  controller: emailController,
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
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  obscureText: true,
                  autofillHints: [AutofillHints.password],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: LoginPost,
                  child: Text('Next'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 60),
                    backgroundColor: Colors.yellow,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PasswordResetScreen()),
                    );
                  },
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => SignupScreen()),
                    );
                  },
                  child: Text(
                    'Don\'t have an account? Sign up',
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
