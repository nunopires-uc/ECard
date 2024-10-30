import 'package:bcard3/screens/defaultHome.dart';
import 'package:bcard3/screens/login_screen.dart';
import 'package:bcard3/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bcard3/screens/home_screen.dart';
import 'package:bcard3/screens/defaultHome.dart'; // Import CardHome screen
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Define the Contact model
class Contact {
  final String id;
  final String name;
  final String company;
  final String profileImageUrl;

  Contact({
    required this.id,
    required this.name,
    required this.company,
    required this.profileImageUrl,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      name: json['name'] as String,
      company: json['company'] as String,
      profileImageUrl: json['profileImageUrl'] as String,
    );
  }
}

// Define ContactsProvider for state management
class ContactsProvider with ChangeNotifier {
  List<Contact> _contacts = [];
  bool _contactsUpdated = false;
  DateTime? _lastFetchTime;

  List<Contact> get contacts => _contacts;

  Future<void> fetchContacts(String userId) async {
    if (_contactsUpdated && _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < Duration(hours: 24)) {
      return;
    }
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot snapshot = await firestore.collection('users')
          .doc(userId)
          .collection('contacts')
          .get();

      _contacts = snapshot.docs.map((doc) {
        return Contact.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();

      _contactsUpdated = true;
      _lastFetchTime = DateTime.now();
      notifyListeners();
    } catch (e) {
      print('Failed to fetch contacts: $e');
    }
  }

  void clearContacts() {
    _contacts = [];
    _contactsUpdated = false;
    _lastFetchTime = null;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ContactsProvider()), // Provide ContactsProvider
      ],
      child: MaterialApp(
        theme: ThemeData(
          textTheme: const TextTheme(
            bodyMedium: TextStyle(
              fontFamily: 'Ubuntu',
            ),
          ),
        ),
        initialRoute: HomeScreen.id,
        routes: {
          HomeScreen.id: (context) => HomeScreen(),
          LoginScreen.id: (context) => const LoginScreen(),
          SignUpScreen.id: (context) => const SignUpScreen(),
          CardHome.id: (context) => const CardHome(),
        },
      ),
    );
  }
}
