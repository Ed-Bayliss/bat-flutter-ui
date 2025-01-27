import 'package:burtonaletrail_app/AppApi.dart';
import 'package:burtonaletrail_app/Home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this package in pubspec.yaml
import 'package:rive/rive.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isShowLoading = false;
  bool isShowConfetti = false;
  bool isSecureCodeVisible = false;
  String buttonText = "Let's Get Started";
  String? firstName;
  String? lastName;
  String? mobileNumber;
  String? secureCode;

  late SMITrigger check;
  late SMITrigger error;
  late SMITrigger reset;

  late SMITrigger confetti;

  StateMachineController getRiveController(Artboard artboard) {
    StateMachineController? controller =
        StateMachineController.fromArtboard(artboard, "State Machine 1");
    artboard.addController(controller!);
    return controller;
  }

  Future<void> signIn(BuildContext context) async {
    if (!isSecureCodeVisible) {
      // Validate the form inputs (First Name, Last Name, Mobile Number)
      if (_formKey.currentState!.validate()) {
        setState(() {
          isShowLoading = true;
        });

        _formKey.currentState!.save();
        final response = await http.post(
          Uri.parse(apiServerOTP),
          body: jsonEncode({
            "firstName": firstName,
            "lastName": lastName,
            "mobileNumber": mobileNumber,
          }),
          headers: {"Content-Type": "application/json"},
        );

        setState(() {
          isShowLoading = false;
        });

        if (response.statusCode == 200) {
          // Number validation successful
          setState(() {
            isSecureCodeVisible = true;
            buttonText = "Sign In";
          });
        } else {
          error.fire();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid details or mobile number")),
          );
        }
      }
    } else {
      // Validate the secure code
      if (_formKey.currentState!.validate()) {
        setState(() {
          isShowLoading = true;
        });

        _formKey.currentState!.save();
        final response = await http.post(
          Uri.parse(apiServerOTPValidate),
          body: jsonEncode({
            "mobileNumber": mobileNumber,
            "secureCode": secureCode,
          }),
          headers: {"Content-Type": "application/json"},
        );

        setState(() {
          isShowLoading = false;
        });

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);

          if (jsonResponse['access_token'] != null) {
            final accessToken = jsonResponse['access_token'];
            final refreshToken = jsonResponse['refresh_token'];
            print(accessToken);
            print(refreshToken);
            // Store the access token in shared preferences
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('access_token', accessToken);
            await prefs.setString('refresh_token', refreshToken);

            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
            // Perform actions after storing token
            // check.fire();
            // Future.delayed(Duration(seconds: 2), () {
            //   setState(() {
            //     isShowConfetti = true;
            //   });
            //   confetti.fire();
            // });
          }
        } else {
          error.fire();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid secure code")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isSecureCodeVisible) ...[
                const Text(
                  "Firstname",
                  style: TextStyle(color: Colors.black54),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 16),
                  child: TextFormField(
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Please enter your first name.";
                      }
                      return null;
                    },
                    onSaved: (value) {
                      firstName = value;
                    },
                    decoration: const InputDecoration(
                      hintText: "Please enter your first name",
                    ),
                  ),
                ),
                const Text(
                  "Surname",
                  style: TextStyle(color: Colors.black54),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 16),
                  child: TextFormField(
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Please enter your last name.";
                      }
                      return null;
                    },
                    onSaved: (value) {
                      lastName = value;
                    },
                    decoration: const InputDecoration(
                      hintText: "Please enter your last name",
                    ),
                  ),
                ),
                const Text(
                  "Mobile",
                  style: TextStyle(color: Colors.black54),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 16),
                  child: TextFormField(
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Please enter your mobile number.";
                      }
                      return null;
                    },
                    onSaved: (value) {
                      mobileNumber = value;
                    },
                    decoration: const InputDecoration(
                      hintText: "Please enter your mobile number.",
                    ),
                  ),
                ),
              ],
              if (isSecureCodeVisible) ...[
                const Text(
                  "Secure Code",
                  style: TextStyle(color: Colors.black54),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 16),
                  child: TextFormField(
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Please enter your secure code.";
                      }
                      return null;
                    },
                    onSaved: (value) {
                      secureCode = value;
                    },
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: "Please enter your secure code.",
                    ),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 24),
                child: ElevatedButton.icon(
                  onPressed: () => signIn(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF77D8E),
                    minimumSize: const Size(double.infinity, 56),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                        bottomLeft: Radius.circular(25),
                      ),
                    ),
                  ),
                  icon: const Icon(
                    CupertinoIcons.arrow_right,
                    color: Color(0xFFFE0037),
                  ),
                  label: Text(buttonText),
                ),
              ),
            ],
          ),
        ),
        if (isShowLoading)
          CustomPositioned(
            child: RiveAnimation.asset(
              "assets/RiveAssets/check.riv",
              onInit: (artboard) {
                StateMachineController controller = getRiveController(artboard);
                check = controller.findSMI("Check") as SMITrigger;
                error = controller.findSMI("Error") as SMITrigger;
                reset = controller.findSMI("Reset") as SMITrigger;
              },
            ),
          ),
        if (isShowConfetti)
          CustomPositioned(
            child: Transform.scale(
              scale: 6,
              child: RiveAnimation.asset(
                "assets/RiveAssets/confetti.riv",
                onInit: (artboard) {
                  StateMachineController controller =
                      getRiveController(artboard);
                  confetti =
                      controller.findSMI("Trigger explosion") as SMITrigger;
                },
              ),
            ),
          ),
      ],
    );
  }
}

class CustomPositioned extends StatelessWidget {
  const CustomPositioned({super.key, required this.child, this.size = 100});
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            height: size,
            width: size,
            child: child,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
