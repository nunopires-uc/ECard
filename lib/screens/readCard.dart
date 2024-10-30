import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReadCardUI extends StatefulWidget {
  final String userId;
  final VoidCallback? onClose; // Add the onClose callback parameter

  ReadCardUI({required this.userId, this.onClose});

  @override
  State<ReadCardUI> createState() => _ReadCardUIState();
}

class _ReadCardUIState extends State<ReadCardUI> {
  Color selectedColor = Color(0xff004aad);
  String? _profileImageUrl;
  late TextEditingController _nameController;
  late TextEditingController _jobTitleController;
  late TextEditingController _locationController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _empresaController;

  File? _imageFile;

  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with default values
    _nameController = TextEditingController(text: 'Abby Williams');
    _jobTitleController = TextEditingController(text: 'Flutter developer');
    _phoneController = TextEditingController(text: '(123) 456 7890');
    _emailController = TextEditingController(text: 'abbywill@example.com');
    _empresaController = TextEditingController(text: 'A sua empresa');

    _loadUserData(widget.userId);
  }

  Future<void> _loadUserData(String userId) async {
    if (user != null) {
      try {
        // Get reference to Firestore
        FirebaseFirestore firestore = FirebaseFirestore.instance;

        // Fetch the user document from 'users' collection based on userId
        DocumentSnapshot userDoc = await firestore.collection('users').doc(userId).get();

        if (userDoc.exists) {
          // Extract data from the document
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

          // Populate the controllers with data from Firestore
          setState(() {
            _nameController.text = data['name'] ?? _nameController.text;
            _jobTitleController.text = data['job'] ?? _jobTitleController.text;
            _phoneController.text = data['phone'] ?? _phoneController.text;
            _emailController.text = data['email'] ?? _emailController.text;
            _empresaController.text = data['company'] ?? _empresaController.text;
            selectedColor = Color(int.parse(data['colour'] ?? '0xff004aad'));
            _profileImageUrl = data['profileImageUrl'];
          });
        } else {
          print("No user data found for uid: ${user!.uid}");
        }
      } catch (e) {
        print("Failed to load user data: $e");
      }
    } else {
      print("No user is currently signed in.");
    }
  }

  Future<void> _saveContact(String userId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      List<String> contacts = [];

      if (userDoc.exists && userDoc.data()?['contacts'] != null) {
        contacts = List<String>.from(userDoc.data()?['contacts']);
      }

      if (!contacts.contains(userId)) {
        contacts.add(userId);
        await userRef.update({'contacts': contacts});
        print("Contact saved successfully.");
      } else {
        print("Contact already exists.");
      }
    } catch (e) {
      print("Error saving contact: $e");
    }
  }


  @override
  void dispose() {
    // Dispose of the controllers
    if (widget.onClose != null) widget.onClose!();
    _nameController.dispose();
    _jobTitleController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _empresaController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (widget.onClose != null) widget.onClose!(); // Call the onClose callback
    return true; // Allow the pop action
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope( // Use WillPopScope here
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Container(
            width: MediaQuery.of(context).size.width,
            color: Colors.white,
            child: CustomPaint(
              painter: CurvePainter(selectedColor),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                  // Avatar
                  GestureDetector(
                    child: Container(
                      padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                      child: CircleAvatar(
                        radius: MediaQuery.of(context).size.width * 0.15, // Adjusted size
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: MediaQuery.of(context).size.width * 0.12, // Adjusted size
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!) // Display selected image from file picker
                              : (_profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!) // Display Firebase image URL
                              : AssetImage('assets/images/logo.png')) as ImageProvider, // Default image
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 0.3),
                  // Editable Name
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: TextField(
                      controller: _nameController,
                      textAlign: TextAlign.center,
                      readOnly: true,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        letterSpacing: 1.15,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  // Editable Job Title
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: TextField(
                      controller: _jobTitleController,
                      readOnly: true,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 18,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  SizedBox(height: 40,),
                  Divider(
                    thickness: 1.15,
                    indent: MediaQuery.of(context).size.width * 0.1,
                    endIndent: MediaQuery.of(context).size.width * 0.1,
                    color: Colors.grey.shade400,
                  ),

                  // Non-editable OVERVIEW text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.12,
                        height: 20,
                      ),
                      Text(
                        'DESCRIÇÃO',
                        style: TextStyle(
                          fontSize: 20,
                          letterSpacing: 1.15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Editable Phone Number
                  Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    padding: EdgeInsets.fromLTRB(20, 3, 1, 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.all(
                        Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TELEMÓVEL',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  letterSpacing: 1.15,
                                ),
                              ),
                              SizedBox(height: 3),
                              TextField(
                                controller: _phoneController,
                                readOnly: true,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  letterSpacing: 1.1,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.09,
                          height: MediaQuery.of(context).size.width * 0.09,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.greenAccent.shade400,
                          ),
                          child: Icon(
                            CupertinoIcons.phone,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  // Editable Email
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      padding: EdgeInsets.fromLTRB(20, 3, 1, 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(
                          Radius.circular(20),
                        ),
                        color: Colors.grey.shade100,
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EMAIL',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.15,
                                  ),
                                ),
                                SizedBox(height: 3),
                                TextField(
                                  controller: _emailController,
                                  readOnly: true,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                    letterSpacing: 1.1,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.09,
                            height: MediaQuery.of(context).size.width * 0.09,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.redAccent,
                            ),
                            child: Icon(
                              CupertinoIcons.mail,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  // Editable Company
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      padding: EdgeInsets.fromLTRB(20, 3, 1, 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(
                          Radius.circular(20),
                        ),
                        color: Colors.grey.shade100,
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EMPRESA',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.15,
                                  ),
                                ),
                                SizedBox(height: 3),
                                TextField(
                                  controller: _empresaController,
                                  readOnly: true,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                    letterSpacing: 1.1,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.09,
                            height: MediaQuery.of(context).size.width * 0.09,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blueAccent,
                            ),
                            child: Icon(
                              CupertinoIcons.building_2_fill,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _saveContact(widget.userId);
                    },
                    child: Text('Guardar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CurvePainter extends CustomPainter {
  final Color color;

  CurvePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = color;
    var path = Path();
    path.lineTo(0.0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0.0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
