import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:burtonaletrail_app/DonateThankyou.dart';
import 'package:burtonaletrail_app/Home.dart';
import 'package:burtonaletrail_app/Login.dart';
import 'package:burtonaletrail_app/QRScanner.dart';
import 'package:burtonaletrail_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class Donate extends StatefulWidget {
  final String url;

  Donate({required this.url});

  @override
  _DonateState createState() => _DonateState();
}

class _DonateState extends State<Donate> {
  InAppWebViewController? _webViewController;
  double _progress = 0;
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      print(widget.url);
    });

    switch (index) {
      case 0:
        // Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        break;
      case 1:
        // Scan
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => QRScanner()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onHorizontalDragUpdate: (updateDetails) {},
                  // onVerticalDragUpdate: (updateDetails) {},
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: Uri.parse(widget.url),
                      method: 'GET',
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
                          applePayAPIEnabled: true),
                    ),
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                    },
                    onProgressChanged: (controller, progress) {
                      setState(() {
                        _progress = progress / 100;
                      });
                    },
                    onReceivedServerTrustAuthRequest:
                        (controller, challenge) async {
                      print(challenge);
                      return ServerTrustAuthResponse(
                          action: ServerTrustAuthResponseAction.PROCEED);
                    },
                    shouldOverrideUrlLoading:
                        (controller, navigationAction) async {
                      final url = navigationAction.request.url?.toString();
                      if (url != null && url.contains('pawtul.com/login')) {
                        // Clear all shared preferences
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        await prefs.clear();

                        // Redirect to the LoginScreen
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginScreen()),
                        );
                        return NavigationActionPolicy.CANCEL;
                      }
                      if (url != null &&
                          url.contains('pawtul.com/thankyou_donate')) {
                        // Redirect to the LoginScreen
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DonateThankyouScreen()),
                        );
                        return NavigationActionPolicy.CANCEL;
                      }
                      return NavigationActionPolicy.ALLOW;
                    },
                  ),
                ),
              ),
            ],
          ),
          if (_progress < 1.0) LoadingOverlay(progress: _progress),
          // Bottom Navigation Bar with blur effect
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                  child: BottomNavigationBar(
                    backgroundColor: Colors.transparent,
                    items: const <BottomNavigationBarItem>[
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.qr_code_scanner),
                        label: 'Scan',
                      ),
                    ],
                    currentIndex: 0,
                    selectedItemColor: Colors.white,
                    unselectedItemColor: Colors.white,
                    onTap: _onItemTapped,
                  ),
                ),
              ),
            ),
          ),
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
