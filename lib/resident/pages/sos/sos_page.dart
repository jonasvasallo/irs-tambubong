import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_capstone/constants.dart';
import 'package:irs_capstone/core/utilities.dart';
import 'package:irs_capstone/models/user_model.dart';
import 'package:irs_capstone/widgets/input_button.dart';

class SosPage extends StatefulWidget {
  const SosPage({Key? key}) : super(key: key);

  @override
  _SosPageState createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> {
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
      CollectionReference sosCollection =
          FirebaseFirestore.instance.collection('sos');

      DocumentReference newDocument = await sosCollection.add({
        'user_id': FirebaseAuth.instance.currentUser?.uid,
        'status': "Active",
        'timestamp': FieldValue.serverTimestamp(),
        'responders': [],
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        }
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
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error ${snapshot.error}');
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    Map<String, dynamic>? userData = snapshot.data?.data();
                    bool isVerified = userData?['verified'] ?? false;
                    if (isVerified) {
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
                                      onPressed: () {
                                        Navigator.pop(context);

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
                    } else {
                      return Text(
                        "Your account must be verified in order to use this feature",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
