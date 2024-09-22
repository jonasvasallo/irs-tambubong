import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/models/incident_model.dart';
import 'package:irs_app/widgets/input_button.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:location/location.dart' as loc;
import 'package:url_launcher/url_launcher.dart';

class EmergencyRespondSection extends StatefulWidget {
  final String id;
  const EmergencyRespondSection({Key? key, required this.id}) : super(key: key);

  @override
  _EmergencyRespondSectionState createState() =>
      _EmergencyRespondSectionState();
}

class _EmergencyRespondSectionState extends State<EmergencyRespondSection> {
  File? selectedImage;
  Image imageShown = Image.network(
    "https://i.stack.imgur.com/l60Hf.png",
    fit: BoxFit.cover,
  );
  Future _pickImageFromGallery() async {
    final returnedImage =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (returnedImage == null) return;

    setState(() {
      selectedImage = File(returnedImage.path);
      imageShown = Image.file(
        selectedImage!,
        fit: BoxFit.cover,
      );
    });
  }

  endResponse() async {
    if (selectedImage == null) {
      Utilities.showSnackBar("You must attach a photo first", Colors.red);
      return;
    }
    BuildContext dialogContext = context;
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (dialogcontext) {
          dialogContext = dialogcontext;
          return Center(
            child: CircularProgressIndicator(
              color: accentColor,
            ),
          );
        });
    try {
      var urlDownload = "";

      if (selectedImage != null) {
        final path =
            '/emergency-attachments/response-proof/${widget.id}/${selectedImage!.path.split('/').last}';

        final ref = FirebaseStorage.instance.ref().child(path);
        UploadTask? uploadTask = ref.putFile(selectedImage!);

        final snapshot = await uploadTask!.whenComplete(() => null);

        urlDownload = await snapshot.ref.getDownloadURL();
      }

      DocumentSnapshot emergencyDoc = await FirebaseFirestore.instance
          .collection('sos')
          .doc(widget.id)
          .get();
      Map<String, dynamic>? emergencyData =
          emergencyDoc.data() as Map<String, dynamic>;

      if (emergencyData.isNotEmpty &&
          (emergencyData['status'] != 'Resolved' ||
              emergencyData['status'] != 'Closed')) {
        await FirebaseFirestore.instance
            .collection('sos')
            .doc(widget.id)
            .update({
          'status': 'Resolved',
        });
      }

      await FirebaseFirestore.instance.collection('sos').doc(widget.id).update({
        'responders': FirebaseAuth.instance.currentUser!.uid,
      });

      await FirebaseFirestore.instance
          .collection('sos')
          .doc(widget.id)
          .collection('responders')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        'status': 'Responded',
        'response_end': FieldValue.serverTimestamp(),
        'response_photo': urlDownload,
      });
      Navigator.of(dialogContext).pop();
    } catch (ex) {
      Navigator.of(dialogContext).pop();
      Utilities.showSnackBar("$ex", Colors.red);

      return;
    }
    context.go('/tanod_home');
  }

  Future<Map<String, dynamic>> getEmergencyDetails() async {
    Map<String, dynamic> emergencyDetails = {};

    try {
      DocumentSnapshot emergencySnapshot = await FirebaseFirestore.instance
          .collection('sos')
          .doc(widget.id)
          .get();
      if (emergencySnapshot.exists) {
        emergencyDetails = emergencySnapshot.data() as Map<String, dynamic>;

        String reportedById = emergencyDetails['user_id'];
        if (reportedById != null) {
          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(reportedById)
              .get();
          if (userSnapshot.exists) {
            emergencyDetails['user_details'] = userSnapshot.data();
          } else {
            print("User does not exist");
          }
        } else {
          print("user_id field is null");
        }
      } else {
        print("incident does not exist");
      }
    } catch (ex) {
      print("$ex");
    }

    return emergencyDetails;
  }

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

    await Geolocator.getCurrentPosition().then((value) {
      return value;
    });

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getEmergencyDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text("${snapshot.error}"),
          );
        }

        Map<String, dynamic> emergencyDetails = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 8,
                  decoration: BoxDecoration(
                    color: majorText,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                SizedBox(
                  height: 16,
                ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            "",
                            style: CustomTextStyle.subheading,
                            textAlign: TextAlign.left,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () async {
                                print("this is firing");
                                final currentLocation =
                                    await _getCurrentLocation();
                                await launchUrl(Uri.parse(
                                    "https://www.google.com/maps/dir/${currentLocation.latitude},${currentLocation.longitude}/${emergencyDetails['location']['latitude']},${emergencyDetails['location']['longitude']}/@14.9698574,120.9302176,16z?entry=ttu"));
                              },
                              icon: Icon(
                                Icons.navigation_outlined,
                                color: Colors.blueAccent,
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection("sos")
                                    .doc(widget.id)
                                    .update({"status": "Active"});
                                await FirebaseFirestore.instance
                                    .collection('sos')
                                    .doc(widget.id)
                                    .collection('responders')
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .update({'status': 'Assigned'});
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                "EXIT",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Divider(
                      color: minorText,
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${emergencyDetails['user_details']['first_name']} ${emergencyDetails['user_details']['last_name']}",
                              style: CustomTextStyle.subheading,
                            ),
                            Text(
                              emergencyDetails['user_details']['contact_no'],
                              style: CustomTextStyle.regular_minor,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton.filled(
                              onPressed: () async {
                                await FlutterPhoneDirectCaller.callNumber(
                                    "${emergencyDetails['user_details']['contact_no']}");
                              },
                              icon: Icon(
                                Icons.call,
                              ),
                              style: IconButton.styleFrom(
                                  backgroundColor: minorText),
                            ),
                            IconButton.filled(
                              onPressed: () {
                                context.go(
                                    '/tanod_home/emergency-details/${widget.id}/respond/${widget.id}/${emergencyDetails['location']['latitude']}/${emergencyDetails['location']['longitude']}/chatroom/${widget.id}');
                              },
                              icon: Icon(
                                Icons.message,
                              ),
                              style: IconButton.styleFrom(
                                  backgroundColor: minorText),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Divider(
                      color: minorText,
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: () {
                          print("working");
                          _pickImageFromGallery();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              color: minorText,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              "Take a photo",
                              style: CustomTextStyle.regular_minor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    (selectedImage != null)
                        ? Stack(
                            children: [
                              Image.file(selectedImage!),
                              TextButton(
                                  onPressed: () {
                                    setState(() {
                                      selectedImage = null;
                                    });
                                  },
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ))
                            ],
                          )
                        : SizedBox(),
                    SizedBox(
                      height: 16,
                    ),
                    InputButton(
                      label: "End Response",
                      function: endResponse,
                      large: true,
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
}
