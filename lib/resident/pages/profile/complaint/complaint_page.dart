import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/input_validator.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/widgets/input_button.dart';
import 'package:irs_app/widgets/input_field.dart';

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({Key? key}) : super(key: key);

  @override
  _ComplaintPageState createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final _fullNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  late StreamController<List<Map<String, dynamic>>> _streetsStreamController;
  late List<Map<String, dynamic>> _streets;

  Widget initialScreen = Center(
    child: Text("Test"),
  );

  Widget currentScreen = SizedBox();

  Widget unknownScreen = Center(
    child: Text("Unknown"),
  );
  Widget knownScreen = Center(
    child: Text("Known"),
  );

  @override
  void initState() {
    currentScreen = initialScreen;
    super.initState();
    _streetsStreamController = StreamController<List<Map<String, dynamic>>>();
    _streets = [];

    // Fetch incident tags when the widget is initialized
    getStreets().then((tags) {
      _streetsStreamController.add(tags);
    });
  }

  Stream<List<Map<String, dynamic>>> get streetsStream =>
      _streetsStreamController.stream;

  Future<List<Map<String, dynamic>>> getStreets() async {
    List<Map<String, dynamic>> streets = [];

    try {
      QuerySnapshot tagsSnapshot =
          await FirebaseFirestore.instance.collection('streets').get();

      if (tagsSnapshot.docs.isNotEmpty) {
        for (var tagDocument in tagsSnapshot.docs) {
          Map<String, dynamic> tagData =
              tagDocument.data() as Map<String, dynamic>;
          streets.add({
            'street_id': tagDocument.id,
            'street_name': tagData['name'],
            // Add more fields if needed
          });
        }
      } else {
        print('No tags found in the incident_tags collection.');
      }
    } catch (ex) {
      print('Error fetching incident tags: $ex');
    }

    return streets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("File a Complaint"),
        actions: [
          IconButton(onPressed: () => Utilities.launchURL(Uri.parse("https://youtu.be/BAhbqZeUmhc?si=VU4Y8ykjn4ynjSSL&t=332"), true), icon: Icon(Icons.help_outline_rounded),),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Do you know the name of the individual?",
              style: CustomTextStyle.subheading,
              textAlign: TextAlign.center,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    context.go('/profile/complaint/known');
                  },
                  child: Text(
                    "Yes",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.go('/profile/complaint/unknown');
                  },
                  child: Text(
                    "No",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
