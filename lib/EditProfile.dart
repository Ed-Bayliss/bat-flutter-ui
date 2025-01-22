import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:burtonaletrail_app/AppApi.dart';
import 'package:burtonaletrail_app/AppColors.dart';
import 'package:burtonaletrail_app/AppDrawer.dart';
import 'package:burtonaletrail_app/AppMenuButton.dart';
import 'package:burtonaletrail_app/NavBar.dart';
import 'package:http/io_client.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:rive/rive.dart' as rive;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;

class EditProfileScreen extends StatefulWidget {
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController userNameController;
  late TextEditingController userFirstnameController;
  late TextEditingController userSurnameController;
  late TextEditingController userMobileController;
  late TextEditingController userEmailController;
  String profileImageBase64 = '';

  @override
  void initState() {
    super.initState();
    userNameController = TextEditingController();
    userFirstnameController = TextEditingController();
    userSurnameController = TextEditingController();
    userMobileController = TextEditingController();
    userEmailController = TextEditingController();
    _fetchUserData();
  }

  @override
  void dispose() {
    userNameController.dispose();
    userFirstnameController.dispose();
    userSurnameController.dispose();
    userMobileController.dispose();
    userEmailController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userNameController.text = prefs.getString('userName') ?? '';
      userFirstnameController.text = prefs.getString('userFirstname') ?? '';
      userSurnameController.text = prefs.getString('userSurname') ?? '';
      userMobileController.text = prefs.getString('userMobile') ?? '';
      userEmailController.text = prefs.getString('userEmail') ?? '';
      profileImageBase64 = prefs.getString('userImage') ?? '';
    });
  }

  Future<void> _saveUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? accessToken = prefs.getString('access_token');

    if (accessToken != null) {
      // Check if any of the required fields are null or empty
      if (userNameController.text.isEmpty ||
          userFirstnameController.text.isEmpty ||
          userSurnameController.text.isEmpty ||
          userMobileController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill in all fields before saving.')),
        );
        return;
      }

      bool trustSelfSigned = true;
      HttpClient httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => trustSelfSigned;
      IOClient ioClient = IOClient(httpClient);

      try {
        final response = await ioClient.post(Uri.parse(apiServerEditProfile),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'access_token': accessToken,
              'userName': userNameController.text,
              'userFirstname': userFirstnameController.text,
              'userSurname': userSurnameController.text,
              'userMobile': userMobileController.text,
              'userEmail': userEmailController.text,
              'userImage': profileImageBase64
            }));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          await prefs.setString('userName', userNameController.text);
          await prefs.setString('userFirstname', userFirstnameController.text);
          await prefs.setString('userSurname', userSurnameController.text);
          await prefs.setString('userMobile', userMobileController.text);
          // await prefs.setString('userEmail', userEmailController.text);
          if (profileImageBase64 != null) {
            await prefs.setString('userImage', profileImageBase64!);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated sucessfully')),
          );

          // Safely retrieve user and leaderboard data
          setState(() {});
        } else if (response.statusCode == 101) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('This username is too rude.')),
          );
        } else if (response.statusCode == 102) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('This username is already taken.')),
          );
        } else {
          print(
              'Failed to load user data. Status code: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    } else {
      throw Exception('Access token not found');
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Colors.blue,
              toolbarWidgetColor: Colors.white,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Crop Image',
              aspectRatioLockEnabled: true,
            ),
          ],
        );

        if (croppedFile != null) {
          // Read and compress the image
          final originalBytes = await croppedFile.readAsBytes();
          final decodedImage = img.decodeImage(originalBytes);

          if (decodedImage != null) {
            // Compress the image
            var compressedImage = img.encodeJpg(
              decodedImage,
              quality: 70, // Adjust quality to achieve desired size
            );

            // Ensure the file is under 100KB
            int targetSize = 100 * 1024; // 100KB in bytes
            int quality = 70;

            while (compressedImage.length > targetSize && quality > 10) {
              quality -= 5;
              compressedImage = img.encodeJpg(decodedImage, quality: quality);
            }

            setState(() {
              profileImageBase64 = base64Encode(compressedImage);
            });
            _saveUserData();
          }
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      Get.snackbar(
        'Error',
        'An error occurred while picking or cropping the image.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned(
            width: size.width * 1.7,
            bottom: 100,
            left: 100,
            child: Image.asset('assets/Backgrounds/Spline.png'),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 10),
            ),
          ),
          const rive.RiveAnimation.asset('assets/RiveAssets/shapes.riv'),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 10),
              child: const SizedBox(),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(),
                  const SizedBox(height: 20),
                  _profilePictureSection(),
                  const SizedBox(height: 20),
                  _editProfileForm(),
                ],
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(activeItem: 1),
      bottomNavigationBar: CustomBottomNavigationBar(),
    );
  }

  Widget _profilePictureSection() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: profileImageBase64 != null &&
                    profileImageBase64!.isNotEmpty
                ? MemoryImage(base64Decode(profileImageBase64!))
                : const AssetImage('assets/images/marvin.png') as ImageProvider,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String getGreeting() {
    var hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning 👋';
    } else if (hour < 17) {
      return 'Good Afternoon 👋';
    } else {
      return 'Good Evening 👋';
    }
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Builder(
              builder: (context) {
                return AppMenuButton(
                  onTap: () => Scaffold.of(context).openDrawer(),
                );
              },
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getGreeting(),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.normal),
                ),
                const SizedBox(height: 4),
                Text(
                  userNameController.text.isNotEmpty
                      ? userNameController.text
                      : 'Loading...',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                )
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _editProfileForm() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField('Username', userNameController),
            const SizedBox(height: 16),
            _buildTextField('First Name', userFirstnameController),
            const SizedBox(height: 16),
            _buildTextField('Surname', userSurnameController),
            const SizedBox(height: 16),
            _buildTextField('Mobile', userMobileController),
            const SizedBox(height: 16),
            _buildTextField('Email', userEmailController),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  await _saveUserData();
                  Get.snackbar('Success', 'Profile updated successfully!',
                      snackPosition: SnackPosition.BOTTOM);
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
