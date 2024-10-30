import 'package:bcard3/screens/readCardContact.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContactsPage extends StatefulWidget {
  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> contactsData = [];
  List<Map<String, dynamic>> filteredContactsData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _fetchContacts(user!.uid);
    } else {
      setState(() => isLoading = false);
    }
    _searchController.addListener(_filterContacts);
  }

  Future<void> _fetchContacts(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print("User document does not exist.");
        setState(() => isLoading = false);
        return;
      }

      List<dynamic>? contacts = userDoc['contacts'] as List<dynamic>?;

      if (contacts == null || contacts.isEmpty) {
        print("No contacts found for this user.");
        setState(() => isLoading = false);
        return;
      }

      List<Map<String, dynamic>> contactsList = [];
      for (String contactId in contacts) {
        DocumentSnapshot contactDoc = await _firestore.collection('users').doc(contactId).get();

        if (contactDoc.exists && contactDoc.data() != null) {
          Map<String, dynamic> contactData = contactDoc.data() as Map<String, dynamic>;
          contactsList.add({
            'userId': contactData['userId'],
            'profileImageUrl': contactData.containsKey('profileImageUrl')
                ? contactData['profileImageUrl']
                : '',
            'name': contactData['name'],
            'company': contactData['company']
          });
        }
      }

      setState(() {
        contactsData = contactsList;
        filteredContactsData = contactsList;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching contacts: $e');
      setState(() => isLoading = false);
    }
  }

  void _filterContacts() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredContactsData = contactsData.where((contact) {
        return contact['name'].toLowerCase().contains(query) ||
            contact['company'].toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          SizedBox(height: 45,),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Procurar ...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredContactsData.isEmpty
                ? Center(child: Text("Não existem contactos"))
                : ListView.builder(
              itemCount: filteredContactsData.length,
              itemBuilder: (context, index) {
                final contact = filteredContactsData[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: contact['profileImageUrl'] != ''
                        ? NetworkImage(contact['profileImageUrl'])
                        : AssetImage('assets/images/logo.png') as ImageProvider,
                  ),
                  title: Text(contact['name']),
                  subtitle: Text('${contact['company']}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReadCardUI(
                          userId: contact['userId'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
