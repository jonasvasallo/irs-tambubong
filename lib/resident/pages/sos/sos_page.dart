import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/models/user_model.dart';
import 'package:irs_app/widgets/input_button.dart';

class SosPage extends StatefulWidget {
  const SosPage({Key? key}) : super(key: key);

  @override
  _SosPageState createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> {
  File? recordedVideo;
  final picker = ImagePicker();
  Future<bool> pickVideoFromCamera() async {
    final video = await picker.pickVideo(source: ImageSource.camera);
    if (video == null) return false;

    recordedVideo = File(video.path);
    return true;
  }

  late String lat;
  late String long;
  String locationMessage = "";
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error("Location services are disabled");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("Location permissions are denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          "Location permissions are currently denied, we cannot request");
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> addSOS(double latitude, double longitude) async {
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
    try {
      var urlDownload = "";

      if (recordedVideo != null) {
        final path = '/sos_attachments/${recordedVideo!.path.split('/').last}';

        final ref = FirebaseStorage.instance.ref().child(path);
        UploadTask? uploadTask = ref.putFile(recordedVideo!);

        final snapshot = await uploadTask!.whenComplete(() => null);

        urlDownload = await snapshot.ref.getDownloadURL();
      }
      CollectionReference sosCollection =
          FirebaseFirestore.instance.collection('sos');

      DocumentReference newDocument = await sosCollection.add({
        'user_id': FirebaseAuth.instance.currentUser?.uid,
        'status': "Active",
        'timestamp': FieldValue.serverTimestamp(),
        'responders': [],
        'attachment': urlDownload,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
        'rated': false,
      });
      Navigator.of(dialogContext).pop();
      context.go('/sos/ongoing/${newDocument.id}');
    } catch (ex) {
      Utilities.showSnackBar("$ex", Colors.red);
    }
  }

  Future<bool> checkIfVerified() async {
    Map<String, dynamic>? userDetails =
        await UserModel.getUserById(FirebaseAuth.instance.currentUser!.uid);
    if (userDetails == null) {
      return false;
    }

    return userDetails['verified'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Emergency SOS"),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(120)),
                  child: Icon(
                    Icons.warning,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                SizedBox(
                  height: 16,
                ),
                Text(
                  "Emergency SOS using Mobile GPS Technology",
                  textAlign: TextAlign.center,
                  style: CustomTextStyle.heading,
                ),
                SizedBox(
                  height: 8,
                ),
                Text(
                  "Ensure stable internet connection to avoid data loss",
                  textAlign: TextAlign.center,
                  style: CustomTextStyle.regular_minor,
                ),
                SizedBox(
                  height: 16,
                ),
                Text(locationMessage),
                StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('sos')
                      .where('user_id',
                          isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                      .where('status', isEqualTo: 'Active')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      String activeSosDocId = snapshot.data!.docs.first.id;
                      return InputButton(
                          label: "Go back to SOS",
                          function: () {
                            context.go('/sos/ongoing/${activeSosDocId}');
                          },
                          large: true);
                    } else {
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: InputButton(
                          label: "Report Emegency",
                          function: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text("SOS Confirmation"),
                                  content: Text(
                                    "Are you sure you want to use this feature? \n\nNote: Illegitimate calls to government units are punishable by law under Presidential Decree No. 1727.",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(context);

                                        if (!await pickVideoFromCamera()) {
                                          Utilities.showSnackBar(
                                              "Please try again.", Colors.red);
                                          return;
                                        }

                                        _getCurrentLocation().then((value) {
                                          lat = "${value.latitude}";
                                          long = "${value.longitude}";
                                          addSOS(
                                              value.latitude, value.longitude);
                                          print("happening");
                                        });
                                      },
                                      child: Text("Yes"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          large: true,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
