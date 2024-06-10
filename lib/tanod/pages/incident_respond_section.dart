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

class IncidentRespondSection extends StatefulWidget {
  final String id;
  const IncidentRespondSection({Key? key, required this.id}) : super(key: key);

  @override
  _IncidentRespondSectionState createState() => _IncidentRespondSectionState();
}

class _IncidentRespondSectionState extends State<IncidentRespondSection> {
  File? selectedImage;
  Image imageShown = Image.network(
    "https://i.stack.imgur.com/l60Hf.png",
    fit: BoxFit.cover,
  );
  Future _pickImageFromGallery() async {
    final returnedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
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
            '/incident-attachments/response-proof/${selectedImage!.path.split('/').last}';

        final ref = FirebaseStorage.instance.ref().child(path);
        UploadTask? uploadTask = ref.putFile(selectedImage!);

        final snapshot = await uploadTask!.whenComplete(() => null);

        urlDownload = await snapshot.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('incidents')
          .doc(widget.id)
          .update({
        'status': 'Resolved',
      });
      await FirebaseFirestore.instance
          .collection('incidents')
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

  Future<Map<String, dynamic>> getIncidentDetails() async {
    Map<String, dynamic> incidentDetails = {};

    try {
      DocumentSnapshot incidentSnapshot = await FirebaseFirestore.instance
          .collection('incidents')
          .doc(widget.id)
          .get();
      if (incidentSnapshot.exists) {
        incidentDetails = incidentSnapshot.data() as Map<String, dynamic>;

        String reportedById = incidentDetails['reported_by'];
        if (reportedById != null) {
          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(reportedById)
              .get();
          if (userSnapshot.exists) {
            // Include user details in the incidentDetails map
            incidentDetails['user_details'] = userSnapshot.data();
          } else {
            print("User does not exist");
          }

          String incident_tag_id = incidentDetails['incident_tag'];
          if (incident_tag_id != null) {
            DocumentSnapshot incidentTagSnapshot = await FirebaseFirestore
                .instance
                .collection('incident_tags')
                .doc(incident_tag_id)
                .get();

            if (incidentTagSnapshot.exists) {
              incidentDetails['incident_tags_details'] =
                  incidentTagSnapshot.data();
              print(incidentDetails['incident_tags_details']);
            } else {
              print("incident tag does not exist");
            }
          }
        } else {
          print("reported_by field is null");
        }
      } else {
        print("incident does not exist");
      }
    } catch (ex) {
      print("$ex");
    }

    return incidentDetails;
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
      future: getIncidentDetails(),
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

        Map<String, dynamic> incidentDetails = snapshot.data!;

        Incident incident = new Incident(incident_id: widget.id);
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
                            incidentDetails['location_address'],
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
                                    "https://www.google.com/maps/dir/${currentLocation.latitude},${currentLocation.longitude}/${incidentDetails['coordinates']['latitude']},${incidentDetails['coordinates']['longitude']}/@14.9698574,120.9302176,16z?entry=ttu"));
                              },
                              icon: Icon(
                                Icons.navigation_outlined,
                                color: Colors.blueAccent,
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                incident.update({'status': 'Verified'});
                                await FirebaseFirestore.instance
                                    .collection('incidents')
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
                              "${incidentDetails['user_details']['first_name']} ${incidentDetails['user_details']['middle_name'].toString()[0]}. ${incidentDetails['user_details']['last_name']}",
                              style: CustomTextStyle.subheading,
                            ),
                            Text(
                              incidentDetails['user_details']['contact_no'],
                              style: CustomTextStyle.regular_minor,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton.filled(
                              onPressed: () async {
                                await FlutterPhoneDirectCaller.callNumber(
                                    "${incidentDetails['user_details']['contact_no']}");
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
                                    '/tanod_home/incident-details/${widget.id}/respond/${widget.id}/${incidentDetails['coordinates']['latitude']}/${incidentDetails['coordinates']['longitude']}/chatroom/${widget.id}');
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
                    Text(
                      incidentDetails['title'],
                      style: CustomTextStyle.subheading,
                    ),
                    Text(
                      Utilities.convertDate(incidentDetails['timestamp']),
                      style: CustomTextStyle.regular_minor,
                    ),
                    Text(
                      incidentDetails['details'],
                      style: CustomTextStyle.regular,
                      textAlign: TextAlign.center,
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
