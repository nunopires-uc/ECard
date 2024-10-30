import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:bcard3/screens/qrscanner.dart';


/*
Falta: Carregar quando se entra na pagina inicial
Mensagem de Sucesso:
Pagina para dar logout
 */


class BusinessCardUI extends StatefulWidget {
  @override
  State<BusinessCardUI> createState() => _BusinessCardUIState();
}

class _BusinessCardUIState extends State<BusinessCardUI> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  Color selectedColor = Color(0xff004aad);
  String? _profileImageUrl;
  late TextEditingController _nameController;
  late TextEditingController _jobTitleController;
  late TextEditingController _locationController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _empresaController;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  User? user = FirebaseAuth.instance.currentUser;
  bool _isScannerVisible = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with default values
    _nameController = TextEditingController(text: 'O seu nome');
    _jobTitleController = TextEditingController(text: 'O meu cargo');
    _phoneController = TextEditingController(text: '(123) 456 7890');
    _emailController = TextEditingController(text: 'email@example.com');
    _empresaController = TextEditingController(text: 'A sua empresa');

    _loadUserData();
  }

  Future<void> _pickImage() async {
    // Use ImagePicker to select an image
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToFirebaseStorage(String userId) async {
    if (_imageFile == null) return null;

    try {
      // Create a reference to Firebase Storage with userId
      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('user_images/$userId/profile_image.jpg');

      // Upload the image file
      UploadTask uploadTask = storageReference.putFile(_imageFile!);

      // Wait for the upload to complete and get the download URL
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Failed to upload image: $e');
      return null;
    }
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Escolher uma cor'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (Color color) {
                setState(() {
                  selectedColor = color;
                });
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Selecionar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Color(0xff004aad), // Set your desired text color here
              ),
            ),
          ],
        );
      },
    );
  }


  Future<void> _loadUserData() async {
    if (user != null) {
      try {
        // Get reference to Firestore
        FirebaseFirestore firestore = FirebaseFirestore.instance;

        // Fetch the user document from 'users' collection based on user.uid
        DocumentSnapshot userDoc = await firestore.collection('users').doc(user!.uid).get();

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

  @override
  void dispose() {
    // Dispose of the controllers
    _nameController.dispose();
    _jobTitleController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _empresaController.dispose();
    controller?.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => QRScannerPage()),
          );
        },
        backgroundColor: Color(0xff004aad),
        child: Icon(Icons.qr_code, color: Colors.white),
      ),
      body: Column(
        children: [
        Expanded(
          child: SingleChildScrollView(
            child: GestureDetector(
              onTap: _pickColor,
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
                      onTap: _pickImage,
                      child: Container(
                        padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                        child: CircleAvatar(
                          radius: MediaQuery.of(context).size.width * 0.09,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: MediaQuery.of(context).size.width * 0.08,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : (_profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : AssetImage('assets/images/logo.png')) as ImageProvider,
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
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
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    SizedBox(height: 0.0),
                    Divider(
                      thickness: 1.15,
                      indent: MediaQuery.of(context).size.width * 0.1,
                      endIndent: MediaQuery.of(context).size.width * 0.1,
                      color: Colors.grey.shade400,
                    ),
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
                            fontSize: 14,
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
                                    fontSize: 12,
                                    letterSpacing: 1.15,
                                  ),
                                ),
                                SizedBox(height: 3),
                                TextField(
                                  controller: _phoneController,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
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
                            width: MediaQuery.of(context).size.width * 0.07,
                            height: MediaQuery.of(context).size.width * 0.07,
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
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.15,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  TextField(
                                    controller: _emailController,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      letterSpacing: 1.0,
                                      fontSize: 12,
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
                              width: MediaQuery.of(context).size.width * 0.07,
                              height: MediaQuery.of(context).size.width * 0.07,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.redAccent,
                              ),
                              child: Icon(
                                CupertinoIcons.mail,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    // Editable Empresa
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
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.15,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  TextField(
                                    controller: _empresaController,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      letterSpacing: 1.0,
                                      fontSize: 12,
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width * 0.07,
                              height: MediaQuery.of(context).size.width * 0.07,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blueAccent,
                              ),
                              child: Icon(
                                CupertinoIcons.briefcase,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    Divider(
                      thickness: 1.15,
                      indent: MediaQuery.of(context).size.width * 0.1,
                      endIndent: MediaQuery.of(context).size.width * 0.1,
                      color: Colors.grey.shade400,
                    ),
                    // Non-editable QR Code section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.12,
                          height: 20,
                        ),
                        Text(
                          'QRCode',
                          style: TextStyle(
                            fontSize: 14,
                            letterSpacing: 1.15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    // Add this code where you want the button to appear
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        QrImageView(
                          data: user!.uid.toString(),
                          version: QrVersions.auto,
                          size: 140,
                          gapless: false,
                        )
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () async{
                        final user = this.user;
                        if (user != null) {
                          String userId = user.uid.toString();
                          String name = _nameController.text;
                          String email = _emailController.text;
                          String jobtitle = _jobTitleController.text;
                          String phoneController = _phoneController.text;
                          String empresa = _empresaController.text;
                          String? imageUrl = await _uploadImageToFirebaseStorage(userId);

                          // Data to update or set in Firestore
                          Map<String, dynamic> userData = {
                            'userId': userId,
                            'name': name,
                            'email': email,
                            'phone': phoneController,
                            'job': jobtitle,
                            'company': empresa,
                            'colour': selectedColor.value.toString(),
                            if (imageUrl != null) 'profileImageUrl': imageUrl,
                          };

                          // Use set with merge: true to add or update the user data
                          await FirebaseFirestore.instance.collection('users').doc(userId).set(
                            userData,
                            SetOptions(merge: true),
                          ).then((_) {
                            print('User data added/updated successfully!');
                          }).catchError((error) {
                            print('Failed to add/update user data: $error');
                          });
                        } else {
                          print('No user is currently logged in.');
                        }
                      },
                      child: Text(
                        'Atualizar QR', // The text displayed on the button
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        backgroundColor: Color(0xff004aad), // Background color
                        foregroundColor: Colors.white, // Text color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // Rounded corners
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),
          ),
        )
        ]
      ),
    );
  }
}

class CurvePainter extends CustomPainter {
  final Color color;

  CurvePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(1.0),
          color.withOpacity(0.8),
          color.withOpacity(1.0),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTRB(
        size.width * 0.15,
        size.height * 0.15,
        size.width,
        size.height * 0.1,
      ));

    var path = Path();
    path.moveTo(0, size.height * 0.15);
    path.quadraticBezierTo(
      size.width * 0.48,
      size.height * 0.23,
      size.width,
      size.height * 0.18,
    );
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.23,
      size.width,
      size.height * 0.18,
    );
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CurvePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

