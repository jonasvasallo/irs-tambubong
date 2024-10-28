import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/file_picker_util.dart';
import 'package:irs_app/core/input_validator.dart';
import 'package:irs_app/core/rate_limiter.dart';
import 'package:irs_app/core/status_checker.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/widgets/input_button.dart';
import 'package:irs_app/widgets/input_field.dart';

class UnknownComplaintPage extends StatefulWidget {
  const UnknownComplaintPage({Key? key}) : super(key: key);

  @override
  _UnknownComplaintPageState createState() => _UnknownComplaintPageState();
}

class _UnknownComplaintPageState extends State<UnknownComplaintPage> {
  List<Widget> media_photosers = [];
  late FilePickerUtil filePickerUtil;
  final _descriptionController = TextEditingController();
  final _natureController = TextEditingController();
  final _reliefController = TextEditingController();

  late StreamController<List<Map<String, dynamic>>> _streetsStreamController;
  late List<Map<String, dynamic>> _streets;
  String user_id = "";

  String _dropdownValue = "";

  final formKey = GlobalKey<FormState>();

  void fileComplaint() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (_dropdownValue.isEmpty) {
      Utilities.showSnackBar("You must select the address first", Colors.red);
      return;
    }

    final RateLimiter _rateLimiter = RateLimiter(
      userId: FirebaseAuth.instance.currentUser!.uid,
      keyPrefix: 'action',
      cooldownDuration: Duration(seconds: 5),
    );
    if (!await _rateLimiter.isActionAllowed()) {
      Utilities.showSnackBar(
          "You are doing this action way too quickly!", Colors.red);
      return;
    }

    BuildContext dialogContext = context;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        dialogContext = context;
        return Center(
          child: CircularProgressIndicator(
            color: accentColor,
          ),
        );
      },
    );

    await _rateLimiter.updateLastActionTime();

    final status_checker = StatusChecker();
    final hasActiveIncident = await status_checker.hasActiveDocument(
      collectionName: 'complaints', // Collection to search
      userIdField: 'issued_by', // Field in the document that matches the user
      userId:
          FirebaseAuth.instance.currentUser!.uid, // Current logged-in user's ID
      statusField: 'status', // Field to check the status
      activeStatuses: ['Open', 'In Progress'], // List of active statuses
    );

    if (hasActiveIncident) {
      Navigator.pop(dialogContext);
      Utilities.showSnackBar(
          "You currently have an active complaint!", Colors.red);
      return;
    }

    try {
      List<String> imageUrls = [];

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      Map<String, dynamic> user_Details = {};
      if (userDoc.exists) {
        print(userDoc.data());
        user_Details = userDoc.data() as Map<String, dynamic>;
      } else {
        print('Document does not exist');
        return;
      }

      if (user_Details['verified'] == false) {
        Navigator.of(dialogContext).pop();
        Utilities.showSnackBar(
            "You can only file a complaint once you are verified!", Colors.red);
        return;
      }

      if (filePickerUtil.pickedImagesInBytes.length > 0) {
        imageUrls = await filePickerUtil.uploadMultipleFiles(
            "${user_Details['first_name']}-${user_Details['last_name']}_${FirebaseAuth.instance.currentUser!.uid}");
        print(imageUrls);
      }

      CollectionReference complaintsCollection =
          FirebaseFirestore.instance.collection('complaints');

      await complaintsCollection.add({
        'full_name':
            "${user_Details['first_name']} ${user_Details['last_name']}",
        'contact_no': "${user_Details['contact_no']}",
        'email': user_Details['email'],
        'address':
            "${user_Details['address_house']} ${user_Details['address_street']}",
        'respondent_info': [
          'N/A',
          'N/A',
          "${_dropdownValue}, Tambubong, San Rafael, Bulacan",
        ],
        'respondent_id': user_id,
        'respondent_description': _descriptionController.text.trim(),
        "description": _natureController.text.trim(),
        "relief_manner": _reliefController.text.trim(),
        'supporting_docs': imageUrls,
        'issued_at': FieldValue.serverTimestamp(),
        'issued_by': FirebaseAuth.instance.currentUser!.uid,
        'status': "Open",
      });
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        'complaint_count': FieldValue.increment(1),
      });

      Utilities.showSnackBar("Successfully filed complaint", Colors.green);
      Navigator.of(dialogContext).pop();
      context.go('/profile');
    } catch (ex) {
      Utilities.showSnackBar("$ex", Colors.red);
      Navigator.of(dialogContext).pop();
    }
  }

  void initState() {
    super.initState();
    filePickerUtil = FilePickerUtil("complaints_documents", () {
      setState(() {});
    }, media_photosers);
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
          IconButton(
            onPressed: () => Utilities.launchURL(
                Uri.parse(
                    "https://youtu.be/BAhbqZeUmhc?si=VU4Y8ykjn4ynjSSL&t=332"),
                true),
            icon: Icon(Icons.help_outline_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InputField(
                  placeholder: "Description of the individual...",
                  inputType: "message",
                  controller: _descriptionController,
                  label: "Description",
                  validator: InputValidator.requiredValidator,
                ),
                Text(
                  "Include all relevant details to ensure efficient handling. Leaving out pertinent information may delay the process. ",
                  style: CustomTextStyle.regular_minor,
                  textAlign: TextAlign.left,
                ),
                SizedBox(
                  height: 16,
                ),
                StreamBuilder(
                  stream: streetsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      // Data is still loading
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      // Error occurred while fetching data
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      // No data available
                      return Text('No incident tags found.');
                    } else {
                      // Data has been successfully fetched
                      final _incidentTags = snapshot.data!;

                      return DropdownMenu(
                        hintText: "Street Address",
                        width: MediaQuery.of(context).size.width - 32,
                        onSelected: (value) {
                          _dropdownValue = value!;
                        },
                        dropdownMenuEntries:
                            _incidentTags.map((Map<String, dynamic> tag) {
                          return DropdownMenuEntry(
                              value: "${tag['street_name']} Street",
                              label: "${tag['street_name']} Street");
                        }).toList(),
                      );
                    }
                  },
                ),
                SizedBox(
                  height: 8,
                ),
                InputField(
                  placeholder: "Nature of the complaint...",
                  inputType: "message",
                  controller: _natureController,
                  label: "Nature of complaint",
                  validator: InputValidator.requiredValidator,
                ),
                Text(
                  "Please provide a concise and precise description of your complaint.",
                  style: CustomTextStyle.regular_minor,
                  textAlign: TextAlign.left,
                ),
                InputField(
                  placeholder:
                      "The following relief/s shall be granted to me...",
                  inputType: "message",
                  controller: _reliefController,
                  label: "Relief Manner",
                  validator: InputValidator.requiredValidator,
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      filePickerUtil.selectAFile();
                    });
                    setState(() {});
                    setState(() {});
                  },
                  child: Text(
                    "Attach Media",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: filePickerUtil.media_photos,
                  ),
                ),
                SizedBox(
                  height: 16,
                ),
                InputButton(
                  label: "Submit Complaint",
                  function: () {
                    fileComplaint();
                  },
                  large: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
