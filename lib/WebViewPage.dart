import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:burtonaletrail_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this line
import 'dart:math' as math;


class WebViewPage extends StatefulWidget {
  final String url;
  final String email;
  final String password;

  WebViewPage({required this.url, required this.email, required this.password});

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  InAppWebViewController? _webViewController;
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    // Encode the email and password as JSON for the POST body
    String postData = jsonEncode({
      'email': widget.email,
      'password': widget.password,
    });

    return Scaffold(
      // appBar: PreferredSize(
      //   preferredSize: Size.fromHeight(1.0), // Set your desired smaller height
      //   child: AppBar(
      //     backgroundColor: Color(0xFFDEF6F2), // Example custom background color
      //   ),
      // ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: Uri.parse(widget.url),
                    method: 'POST',
                    body: Uint8List.fromList(utf8.encode(postData)),
                    headers: {
                      'Content-Type': 'application/json',
                    },
                  ),
                  initialOptions: InAppWebViewGroupOptions(
                    crossPlatform: InAppWebViewOptions(
                      useShouldOverrideUrlLoading: true,
                      mediaPlaybackRequiresUserGesture: false,
                      javaScriptEnabled: true,
                      allowFileAccessFromFileURLs: true,
                    ),
                    android: AndroidInAppWebViewOptions(
                      useHybridComposition: true,
                    ),
                    ios: IOSInAppWebViewOptions(
                      allowsInlineMediaPlayback: true,
                    ),
                  ),
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                  },
                  onProgressChanged: (controller, progress) {
                    setState(() {
                      _progress = progress / 100;
                    });
                  },
                  onReceivedServerTrustAuthRequest: (controller, challenge) {
                    setState(() {
                      print(challenge);
                    });
                    return Future.value(ServerTrustAuthResponse(
                        action: ServerTrustAuthResponseAction.PROCEED));
                  },
                  shouldOverrideUrlLoading: (controller, navigationAction) async {
                    final url = navigationAction.request.url?.toString();
                    if (url != null && url.contains('pawtul.com/login')) {
                      // Clear all shared preferences
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      await prefs.clear();

                      // Redirect to the LoginScreen
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                      return NavigationActionPolicy.CANCEL;
                    }
                    return NavigationActionPolicy.ALLOW;
                  },
                ),
              ),
            ],
          ),
          if (_progress < 1.0) LoadingOverlay(progress: _progress),
        ],
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final double progress;

  LoadingOverlay({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // Blurred overlay
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ),
        // Loading indicator
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/images/discoball.gif', // Path to your disco ball GIF
                height: 100,
                width: 100,
              ),
              SizedBox(height: 10),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}