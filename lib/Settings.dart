import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:burtonaletrail_app/Home.dart'; // Import for navigation
import 'package:burtonaletrail_app/QRScanner.dart'; // Import for navigation

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String uuid = '';
  int _selectedIndex = 1; // Set initial index to Settings
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUUID();
  }

  Future<void> _fetchUUID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      uuid = prefs.getString('uuid') ?? '';
    });
  }

  Future<void> _deleteAccount() async {
    if (uuid.isNotEmpty) {
      bool trustSelfSigned = true;
      HttpClient httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => trustSelfSigned;
      IOClient ioClient = IOClient(httpClient);

      final response = await ioClient.delete(Uri.parse(
          'https://burtonaletrail.pawtul.com/delete_account/' + uuid));

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        throw Exception('Failed to delete account');
      }
    }
  }

  Future<void> _saveUsername() async {
    if (uuid.isNotEmpty) {
      if (usernameController.text != '') {
        bool trustSelfSigned = true;
        HttpClient httpClient = HttpClient()
          ..badCertificateCallback =
              (X509Certificate cert, String host, int port) => trustSelfSigned;
        IOClient ioClient = IOClient(httpClient);

        final response = await ioClient.get(Uri.parse(
            'https://burtonaletrail.pawtul.com/set_username/' +
                usernameController.text +
                '/' +
                uuid));
        if (response.statusCode == 200) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SettingsScreen()),
          );
        } else if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please don\'t be offensive.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        } else if (response.statusCode == 202) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('This username is already in use.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          throw Exception('Failed to delete account');
        }
      }
    }
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Privacy Policy'),
          content: SingleChildScrollView(
            child: Text(
                """This privacy policy applies between you, the User of this Website, and Burton Ale Trail, the owner and provider of this Website. Burton Ale Trail takes the privacy of your information very seriously. This privacy policy applies to our use of any and all Data collected by us or provided by you in relation to your use of the Website.

This privacy policy should be read alongside, and in addition to, our End User License Agreement, which can be found at: https://www.burtonaletrail.com/eula.

Please read this privacy policy carefully

Definitions and interpretation
In this privacy policy, the following definitions are used:
Data	
collectively all information that you submit to Burton Ale Trail via the Website. This definition incorporates, where applicable, the definitions provided in the Data Protection Laws;

Cookies	
a small text file placed on your computer by this Website when you visit certain parts of the Website and/or when you use certain features of the Website. Details of the cookies used by this Website are set out in the clause below (Cookies);

Data Protection Laws	
any applicable law relating to the processing of personal Data, including but not limited to the GDPR, and any national implementing and supplementary laws, regulations and secondary legislation;

GDPR	
the UK General Data Protection Regulation;

Burton Ale Trail, we or us	
Burton Ale Trail, a company incorporated in England and Wales with registered number 14353586 whose registered office is at 3 Beveridge Road, Anslow, Staffordshire, DE13 9UG;

UK and EU Cookie Law	
UK and EU Cookie Law the Privacy and Electronic Communications (EC Directive) Regulations 2003 as amended by the Privacy and Electronic Communications (EC Directive) (Amendment) Regulations 2011 & the Privacy and Electronic Communications (EC Directive) (Amendment) Regulations 2018;

User or you	
any third party that accesses the Website and is not either (i) employed by Burton Ale Trail and acting in the course of their employment or (ii) engaged as a consultant or otherwise providing services to Burton Ale Trail and accessing the Website in connection with the provision of such services; and

Website	
the website that you are currently using, https://www.burtonaletrail.com, and any sub-domains of this site unless expressly excluded by their own terms and conditions.

In this privacy policy, unless the context requires a different interpretation:
the singular includes the plural and vice versa;
references to sub-clauses, clauses, schedules or appendices are to sub-clauses, clauses, schedules or appendices of this privacy policy;
a reference to a person includes firms, companies, government entities, trusts and partnerships;
"including" is understood to mean "including without limitation";
reference to any statutory provision includes any modification or amendment of it;
the headings and sub-headings do not form part of this privacy policy.
Scope of this privacy policy


This privacy policy applies only to the actions of Burton Ale Trail and Users with respect to this Website. It does not extend to any websites that can be accessed from this Website including, but not limited to, any links we may provide to social media websites.
For purposes of the applicable Data Protection Laws, Burton Ale Trail is the "data controller". This means that Burton Ale Trail determines the purposes for which, and the manner in which, your Data is processed.
Data collected
We may collect the following Data, which includes personal Data, from you:
name;
contact Information such as email addresses and telephone numbers;
IP address (automatically collected);
web browser type and version (automatically collected);
operating system (automatically collected);
in each case, in accordance with this privacy policy.
How we collect Data


We collect Data in the following ways:
data is given to us by you; and
data is collected automatically.
Data that is given to us by you
Burton Ale Trail will collect your Data in a number of ways, for example:
when you contact us through the Website, by telephone, post, e-mail or through any other means;
in each case, in accordance with this privacy policy.
Data that is collected automatically
To the extent that you access the Website, we will collect your Data automatically, for example:
we automatically collect some information about your visit to the Website. This information helps us to make improvements to Website content and navigation, and includes your IP address, the date, times and frequency with which you access the Website and the way you use and interact with its content.
we will collect your Data automatically via cookies, in line with the cookie settings on your browser. For more information about cookies, and how we use them on the Website, see the section below, headed "Cookies".
Keeping Data secure
We will use technical and organisational measures to safeguard your Data, for example:
access to your account is controlled by a password and a user name that is unique to you.
we store your Data on secure servers.
We are certified to ISO 27001. This family of standards helps us manage your Data and keep it secure.
Technical and organisational measures include measures to deal with any suspected data breach. If you suspect any misuse or loss or unauthorised access to your Data, please let us know immediately by contacting us via this e-mail address: no-reply@burtonaletrail.com.
If you want detailed information from Get Safe Online on how to protect your information and your computers and devices against fraud, identity theft, viruses and many other online problems, please visit www.getsafeonline.org. Get Safe Online is supported by HM Government and leading businesses.
Data retention
Unless a longer retention period is required or permitted by law, we will only hold your Data on our systems for the period necessary to fulfil the purposes outlined in this privacy policy or until you request that the Data be deleted.
Even if we delete your Data, it may persist on backup or archival media for legal, tax or regulatory purposes.
Your rights
You have the following rights in relation to your Data:
Right to access - the right to request (i) copies of the information we hold about you at any time, or (ii) that we modify, update or delete such information. If we provide you with access to the information we hold about you, we will not charge you for this, unless your request is "manifestly unfounded or excessive." Where we are legally permitted to do so, we may refuse your request. If we refuse your request, we will tell you the reasons why.
Right to correct - the right to have your Data rectified if it is inaccurate or incomplete.
Right to erase - the right to request that we delete or remove your Data from our systems.
Right to restrict our use of your Data - the right to "block" us from using your Data or limit the way in which we can use it.
Right to data portability - the right to request that we move, copy or transfer your Data.
Right to object - the right to object to our use of your Data including where we use it for our legitimate interests.
To make enquiries, exercise any of your rights set out above, or withdraw your consent to the processing of your Data (where consent is our legal basis for processing your Data), please contact us via this e-mail address: no-reply@burtonaletrail.com.
If you are not satisfied with the way a complaint you make in relation to your Data is handled by us, you may be able to refer your complaint to the relevant data protection authority. For the UK, this is the Information Commissioner's Office (ICO). The ICO's contact details can be found on their website at https://ico.org.uk/.
It is important that the Data we hold about you is accurate and current. Please keep us informed if your Data changes during the period for which we hold it.
Links to other websites
This Website may, from time to time, provide links to other websites. We have no control over such websites and are not responsible for the content of these websites. This privacy policy does not extend to your use of such websites. You are advised to read the privacy policy or statement of other websites prior to using them.
Changes of business ownership and control
Burton Ale Trail may, from time to time, expand or reduce our business and this may involve the sale and/or the transfer of control of all or part of Burton Ale Trail. Data provided by Users will, where it is relevant to any part of our business so transferred, be transferred along with that part and the new owner or newly controlling party will, under the terms of this privacy policy, be permitted to use the Data for the purposes for which it was originally supplied to us.
We may also disclose Data to a prospective purchaser of our business or any part of it.
In the above instances, we will take steps with the aim of ensuring your privacy is protected.
Cookies
This Website may place and access certain Cookies on your computer. Burton Ale Trail uses Cookies to improve your experience of using the Website and to improve our range of products and services. Burton Ale Trail has carefully chosen these Cookies and has taken steps to ensure that your privacy is protected and respected at all times.
All Cookies used by this Website are used in accordance with current UK and EU Cookie Law.
Strictly necessary
Session Cookie
We use this cookie to keep you logged in"""),
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showEULA() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('End User License Agreement (EULA)'),
          content: SingleChildScrollView(
            child: Text(
                """This End User License Agreement (EULA) applies between you, the User of the software, and Burton Ale Trail, the owner and provider of this software. Burton Ale Trail takes the licensing and usage terms of the software seriously. This EULA applies to your use of the software.

This EULA should be read alongside, and in addition to, any other terms and conditions provided by Burton Ale Trail.

Please read this End User License Agreement carefully

Definitions and interpretation
In this End User License Agreement, the following definitions are used:
Software	
refers to the computer program provided by Burton Ale Trail, including any updates or supplements to it.

User	
refers to any individual or entity that uses the Software.

License	
refers to the permission granted by Burton Ale Trail to use the Software.

Burton Ale Trail, we or us	
Burton Ale Trail, a company incorporated in England and Wales with registered number 14353586 whose registered office is at 3 Beveridge Road, Anslow, Staffordshire, DE13 9UG;

In this End User License Agreement, unless the context requires a different interpretation:
the singular includes the plural and vice versa;
references to sub-clauses, clauses, schedules or appendices are to sub-clauses, clauses, schedules or appendices of this EULA;
a reference to a person includes firms, companies, government entities, trusts and partnerships;
"including" is understood to mean "including without limitation";
reference to any statutory provision includes any modification or amendment of it;
the headings and sub-headings do not form part of this EULA.
Grant of License


This End User License Agreement grants you a personal, non-exclusive, non-transferable license to use the Software in accordance with the terms and conditions set forth herein.
The License is granted for the period defined by Burton Ale Trail and is subject to termination or revocation as outlined in this EULA.
Scope of License
The License is limited to the use of the Software as defined by its intended functionality and purpose.
Any unauthorized use, reproduction, or distribution of the Software is strictly prohibited and may result in legal action.
Intellectual Property Rights
The Software and all associated intellectual property rights are owned by Burton Ale Trail.
No ownership rights are transferred to you under this EULA.
Limitation of Liability
In no event shall Burton Ale Trail be liable for any damages arising out of the use or inability to use the Software.
Burton Ale Trail shall not be liable for any indirect, consequential, or incidental damages arising out of the use of the Software.
This limitation of liability applies even if Burton Ale Trail has been advised of the possibility of such damages.
Termination
This License is effective until terminated by you or Burton Ale Trail.
You may terminate the License at any time by discontinuing the use of the Software.
Burton Ale Trail reserves the right to terminate the License at any time without prior notice if you fail to comply with any term or condition of this EULA.
Governing Law
This End User License Agreement shall be governed by and construed in accordance with the laws of England and Wales.
Any disputes arising out of or in connection with this EULA shall be subject to the exclusive jurisdiction of the courts of England and Wales.
Changes to this End User License Agreement
Burton Ale Trail reserves the right to change this EULA as deemed necessary from time to time or as may be required by law.
Any changes will be immediately effective upon posting on the Website or through other means provided by Burton Ale Trail.
Continued use of the Software after such changes constitutes acceptance of the revised EULA terms.
If you do not agree to the revised terms, you must discontinue the use of the Software."""),
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _changeUsername() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Username'),
          content: SingleChildScrollView(
            child: TextField(
              controller: usernameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Your new username',
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Send'),
                  onPressed: () {
                    _saveUsername();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _sendFeedback() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Container(
            padding: EdgeInsets.all(16.0),
            constraints: BoxConstraints(maxHeight: 400, maxWidth: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Send Feedback',
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.0),
                Expanded(
                  child: SingleChildScrollView(
                    child: TextField(
                      controller: feedbackController,
                      maxLines: 10,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Your feedback',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: Text('Send'),
                      onPressed: () {
                        _saveFeedback();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _saveFeedback() {
    // Implement the logic to save feedback
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        break;
      case 1:
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
                SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(16.0),
                    children: [
                      ListTile(
                        title: Text('Set Username'),
                        trailing: Icon(Icons.arrow_forward),
                        onTap: _changeUsername,
                      ),
                      Divider(),
                      ListTile(
                        title: Text('Give Feedback'),
                        trailing: Icon(Icons.arrow_forward),
                        onTap: _sendFeedback,
                      ),
                      Divider(),
                      ListTile(
                        title: Text('Privacy Policy'),
                        trailing: Icon(Icons.arrow_forward),
                        onTap: _showPrivacyPolicy,
                      ),
                      Divider(),
                      ListTile(
                        title: Text('End User License Agreement (EULA)'),
                        trailing: Icon(Icons.arrow_forward),
                        onTap: _showEULA,
                      ),
                      Divider(),
                      ListTile(
                        title: Text('Delete Account'),
                        trailing: Icon(Icons.delete, color: Colors.red),
                        onTap: _deleteAccount,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                    currentIndex: _selectedIndex,
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
