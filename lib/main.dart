import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'WebViewPage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON encoding
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart'; // Add this line

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized

  // Initialize OneSignal after Flutter is initialized
  // OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  // OneSignal.initialize(
  //   "3002aa80-35a6-465d-a7dc-6172f15fe72d",
  // );
  // OneSignal.Notifications.requestPermission(true);
  HttpOverrides.global = MyHttpOverrides();

  runApp(MyApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Burton Ale Trail',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
      }
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

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
    // Save email and password from the text controllers to shared preferences
    await prefs.setString('email', emailController.text);
    await prefs.setString('password', passwordController.text);
    LoginPost();
  }
}

  void LoginPost() async {
    String email = emailController.text;
    String password = passwordController.text;
    // String domain = "http://192.168.1.90:8000/";
    String domain = "https://burtonaletrail.pawtul.com/";


    // Save email and password to shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('password', password);

    // Define the URL for the POST request
    String url = domain + 'login_app';

    // Create the JSON body for the POST request
    Map<String, String> body = {
      'email': email,
      'password': password,
      // 'pushSubscriptionId': OneSignal.User.pushSubscription.id.toString()
      'pushSubscriptionId': 'null'
    };

    // Perform the POST request
    try {
      bool trustSelfSigned = true;
      HttpClient httpClient = new HttpClient()
        ..badCertificateCallback =
            ((X509Certificate cert, String host, int port) => trustSelfSigned);
      IOClient ioClient = new IOClient(httpClient);
      var response = await ioClient.post(Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body));
      

      // Check the response status and print the result
      if (response.statusCode == 200) {
        print('Request successful: ${response.body}');
        // Parse the response body to extract external_id
        var responseBody = jsonDecode(response.body);

        // Assuming the responseBody is a list and the first element contains the external_id
        String externalId = responseBody[0]['external_id'];
        // OneSignal.login(externalId);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => WebViewPage(
            url: domain + 'app_login',
            email: email,
            password: password)),
        );

      } else {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Login failed with status: ${response.statusCode}'),
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
            'assets/images/backdrop.jpg', // Path to your background image
            fit: BoxFit.cover, // Makes the image cover the entire screen
          ),
        ),
        // Foreground content
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              Image.asset(
                'assets/app_logo.png', // Path to your asset image
                height: 200,
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
                keyboardType: TextInputType.emailAddress,
                autofillHints: [AutofillHints.username],
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
                child: Text('Login'),
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
              OutlinedButton(
                onPressed: () {},
                child: Text('Client Login'),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: () {},
                child: Text('Don\'t have an account? Sign up',
                style: TextStyle(
                  color: Colors.white, // Sets the text color to white
                 ),
                )
              ),
            ],
          ),
        ),
      ],
    ),
  );

}}