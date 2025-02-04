import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:burtonaletrail_app/AppApi.dart'; // Ensure apiServerEditTeam, apiServerGetTeamMembers, apiServerRemoveTeamMember, and apiServerAddTeamMember are defined here.
import 'package:burtonaletrail_app/AppColors.dart';
import 'package:burtonaletrail_app/AppDrawer.dart';
import 'package:burtonaletrail_app/AppMenuButton.dart';
import 'package:burtonaletrail_app/LoadingScreen.dart';
import 'package:burtonaletrail_app/NavBar.dart';
import 'package:burtonaletrail_app/PrimaryFlatButton.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/io_client.dart';
import 'package:rive/rive.dart' as rive;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;

class EditTeamScreen extends StatefulWidget {
  const EditTeamScreen({super.key});

  @override
  State<EditTeamScreen> createState() => _EditTeamScreenState();
}

class _EditTeamScreenState extends State<EditTeamScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController teamNameController;
  late TextEditingController _newMemberController;
  String teamImageBase64 = '';
  String userName = '';

  // Updated: teamMembers is now a List of Maps containing member info.
  List<Map<String, dynamic>> teamMembers = [];

  // New state variable to track loading status.
  bool _isLoadingTeamMembers = false;

  @override
  void initState() {
    super.initState();
    teamNameController = TextEditingController();
    _newMemberController = TextEditingController();
    _fetchTeamData();
  }

  @override
  void dispose() {
    teamNameController.dispose();
    _newMemberController.dispose();
    super.dispose();
  }

  /// Preloads the team name and team image (as Base64) from local storage.
  Future<void> _fetchTeamData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      teamNameController.text = prefs.getString('userTeam') ?? '';
      teamImageBase64 = prefs.getString('userTeamImage') ?? '';
      userName = prefs.getString('userName') ?? '';
    });
    // After fetching team data, load the team members if the team name is set.
    if (teamNameController.text.isNotEmpty) {
      await _fetchTeamMembers();
    }
  }

  /// Sends the updated team data to the server and stores it locally.
  Future<void> _saveTeamData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    if (teamNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a team name.')),
      );
      return;
    }

    if (accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated.')),
      );
      return;
    }

    // Allow self-signed certificates if needed.
    bool trustSelfSigned = true;
    HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => trustSelfSigned;
    IOClient ioClient = IOClient(httpClient);

    try {
      final response = await ioClient.post(
        Uri.parse(apiServerEditTeam),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'access_token': accessToken,
          'teamName': teamNameController.text,
          'teamImage': teamImageBase64,
        }),
      );

      if (response.statusCode == 200) {
        // Save updated data locally.
        await prefs.setString('teamName', teamNameController.text);
        await prefs.setString('teamImage', teamImageBase64);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team updated successfully')),
        );
        // Optionally, navigate back or to another screen.
        Navigator.pop(context);
      } else {
        print('Failed to update team. Status code: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update team')),
        );
      }
    } catch (e) {
      print('Error updating team: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating team')),
      );
    }
  }

  /// Fetches the team members from the server.
  Future<void> _fetchTeamMembers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    if (accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated.')),
      );
      return;
    }

    setState(() {
      _isLoadingTeamMembers = true;
    });

    bool trustSelfSigned = true;
    HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => trustSelfSigned;
    IOClient ioClient = IOClient(httpClient);

    try {
      final response = await ioClient.post(
        Uri.parse(apiServerGetTeamMembers), // Defined in AppApi.dart.
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'access_token': accessToken,
          'teamName': teamNameController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Use the key 'team_members' per your backend response.
        List<dynamic> membersList = data['team_members'] ?? [];
        setState(() {
          teamMembers = List<Map<String, dynamic>>.from(membersList);
        });
      } else {
        print(
            'Failed to fetch team members. Status code: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load team members')),
        );
      }
    } catch (e) {
      print('Error fetching team members: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching team members')),
      );
    } finally {
      setState(() {
        _isLoadingTeamMembers = false;
      });
    }
  }

  /// Allows the user to pick, crop, and compress an image for the team.
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
              toolbarColor: Colors.red,
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
          final originalBytes = await croppedFile.readAsBytes();
          final decodedImage = img.decodeImage(originalBytes);

          if (decodedImage != null) {
            // Compress the image.
            var compressedImage = img.encodeJpg(decodedImage, quality: 70);
            int targetSize = 100 * 1024; // 100KB
            int quality = 70;

            while (compressedImage.length > targetSize && quality > 10) {
              quality -= 5;
              compressedImage = img.encodeJpg(decodedImage, quality: quality);
            }

            setState(() {
              teamImageBase64 = base64Encode(compressedImage);
            });
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

  /// (Optional) Remove a team member via an API call.
  Future<void> _removeMember(String memberId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    if (accessToken == null) return;

    bool trustSelfSigned = true;
    HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => trustSelfSigned;
    IOClient ioClient = IOClient(httpClient);
    try {
      final response = await ioClient.post(
        Uri.parse(apiServerRemoveTeamMember),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'access_token': accessToken, 'user_id': memberId}),
      );
      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove member')),
        );
      }
    } catch (e) {
      print('Error removing member: $e');
    }
  }

  /// (Optional) Add a new team member via an API call.
  Future<void> _addMember(String memberId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    if (accessToken == null) return;

    bool trustSelfSigned = true;
    HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => trustSelfSigned;
    IOClient ioClient = IOClient(httpClient);
    try {
      final response = await ioClient.post(
        Uri.parse(apiServerAddTeamMember), // Adjust the URL accordingly.
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'access_token': accessToken,
          'user_id': memberId,
        }),
      );
      if (response.statusCode == 408) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This user is already in a team')),
        );
      } else if (response.statusCode == 410) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This user does not exist')),
        );
      }
    } catch (e) {
      print('Error adding member: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Background image and blur effects.
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
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _teamImageSection(),
                  const SizedBox(height: 20),
                  _editTeamForm(),
                  const SizedBox(height: 20),
                  _teamMembersSection(), // Display team members section.
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

  Widget _buildHeader() {
    return Row(
      children: [
        Builder(
          builder: (context) {
            return AppMenuButton(
              onTap: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        const SizedBox(width: 10),
        const Text(
          'Edit Team',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _teamImageSection() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: teamImageBase64.isNotEmpty
                ? MemoryImage(base64Decode(teamImageBase64))
                : const AssetImage('assets/images/default_team.png')
                    as ImageProvider,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
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

  Widget _editTeamForm() {
    return Card(
      color: Colors.white,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField('Team Name', teamNameController),
            const SizedBox(height: 16),
            Center(
              child: PrimaryFlatButton(
                label: 'Save Changes',
                onPressed: () async {
                  await _saveTeamData();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamMembersSection() {
    return Card(
      color: Colors.white,
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Team Members',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Display the list of team members or a progress indicator if loading.
            SizedBox(
              height: 200, // Adjust the height as needed.
              child: _isLoadingTeamMembers
                  ? const Center(
                      child: LoadingScreen(
                      loadingText: "",
                    ))
                  : teamMembers.isEmpty
                      ? const Center(child: Text('No team members found.'))
                      : ListView.separated(
                          itemCount: teamMembers.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final member = teamMembers[index];

                            return ListTile(
                              // Show the member's image if available.
                              leading: (member['user_image'] != null &&
                                      (member['user_image'] as String)
                                          .isNotEmpty)
                                  ? CircleAvatar(
                                      backgroundImage: MemoryImage(
                                        base64Decode(member['user_image']),
                                      ),
                                    )
                                  : const CircleAvatar(
                                      child: Icon(Icons.person)),
                              title: Text(member['user_name'] ?? ''),
                              trailing: member['user_name'] != userName
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        // Remove member logic using the member's user_id.
                                        await _removeMember(
                                            member['user_id'].toString());
                                        setState(() {
                                          teamMembers.removeAt(index);
                                        });
                                      },
                                    )
                                  : IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () async {
                                        // Do nothing or show a message if trying to remove oneself.
                                        setState(() {});
                                      },
                                    ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 16),
            // Row with text field and button to add a new member.
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newMemberController,
                    decoration: const InputDecoration(
                      labelText: 'Add New Member',
                      hintText: 'Enter member user name',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PrimaryFlatButton(
                  onPressed: () async {
                    final newMember = _newMemberController.text.trim();
                    if (newMember.isNotEmpty) {
                      await _addMember(newMember);
                      // After adding, refresh the team members list.
                      await _fetchTeamMembers();
                      _newMemberController.clear();
                    }
                  },
                  label: 'Add',
                ),
              ],
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
