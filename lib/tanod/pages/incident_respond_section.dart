import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

  Future<DateTime> fetchWorldTime() async {
    final url = Uri.parse('http://worldtimeapi.org/api/timezone/Asia/Manila');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final datetime = DateTime.parse(data['datetime']);
      print("fetched time");
      return datetime;
    } else {
      throw Exception('Failed to load time');
    }
  }

  endResponse(reported_by) async {
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
    // Get the current user UID
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Fetch the incident document
    DocumentSnapshot incidentSnapshot = await FirebaseFirestore.instance
        .collection('incidents')
        .doc(widget.id)
        .get();
    if (!incidentSnapshot.exists) {
      Utilities.showSnackBar("Incident does not exist!", Colors.red);
      Navigator.pop(dialogContext);
      return;
    }

    List<dynamic> responders = incidentSnapshot['responders'] ?? [];

    if (!responders.contains(currentUserId)) {
      final localTime = DateTime.now();
      final today6PM =
          DateTime(localTime.year, localTime.month, localTime.day, 18, 0);
      final today6AM =
          DateTime(localTime.year, localTime.month, localTime.day, 6, 0);

      if (localTime.isAfter(today6AM) && localTime.isBefore(today6PM)) {
        Utilities.showSnackBar(
            "You may have been removed as a responder.", Colors.red);
        Navigator.pop(dialogContext);
        return;
      }
    }

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

      // handle case if the incident is an incident head
      DocumentSnapshot incidentDoc = await FirebaseFirestore.instance
          .collection('incidents')
          .doc(widget.id)
          .get();
      if (incidentDoc.exists) {
        DocumentSnapshot incidentResponderDoc = await FirebaseFirestore.instance
            .collection('incidents')
            .doc(widget.id)
            .collection('responders')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get();

        if (incidentResponderDoc.exists) {
          Map<String, dynamic>? incidentResponderData =
              incidentResponderDoc.data() as Map<String, dynamic>?;
          if (incidentResponderData != null &&
              incidentResponderData['response_start'] != null) {
            Map<String, dynamic>? incidentData =
                incidentDoc.data() as Map<String, dynamic>?;
            if (incidentData != null &&
                incidentData['incident_group'] != null) {
              DocumentSnapshot incidentGroupDoc = await FirebaseFirestore
                  .instance
                  .collection('incident_groups')
                  .doc(incidentData['incident_group'])
                  .get();

              if (incidentGroupDoc.exists) {
                Map<String, dynamic>? incidentGroupData =
                    incidentGroupDoc.data() as Map<String, dynamic>?;
                if (incidentGroupData != null) {
                  if (incidentGroupData['head'] == widget.id) {
                    //add the responders in this incident to all incidents within the group
                    if (incidentData['status'] != null) {
                      if (incidentData['status'] == "Resolved" ||
                          incidentData['status'] == "Closed") {
                        for (var incident_in_group
                            in incidentGroupData['in_group']) {
                          await FirebaseFirestore.instance
                              .collection('incidents')
                              .doc(incident_in_group)
                              .collection('responders')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .set({
                            'status': 'Responded',
                            'response_start':
                                incidentResponderData['response_start'],
                            'response_end': FieldValue.serverTimestamp(),
                            'response_photo': urlDownload,
                          });
                        }
                        Navigator.of(dialogContext).pop();
                        context.go('/tanod_home');
                        return;
                      } else {
                        await FirebaseFirestore.instance
                            .collection('incident_groups')
                            .doc(incidentData['incident_group'])
                            .update({
                          'status': 'Resolved',
                        });
                        for (var incident_in_group
                            in incidentGroupData['in_group']) {
                          DocumentSnapshot individualIncidentDoc =
                              await FirebaseFirestore.instance
                                  .collection('incidents')
                                  .doc(incident_in_group)
                                  .get();
                          if (individualIncidentDoc.exists) {
                            Map<String, dynamic>? individualIncidentData =
                                individualIncidentDoc.data()
                                    as Map<String, dynamic>?;
                            if (individualIncidentData != null) {
                              await FirebaseFirestore.instance
                                  .collection('incidents')
                                  .doc(incident_in_group)
                                  .update({
                                'status': 'Resolved',
                              });

                              await FirebaseFirestore.instance
                                  .collection('incidents')
                                  .doc(incident_in_group)
                                  .collection('responders')
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .set({
                                'status': 'Responded',
                                'response_start':
                                    incidentResponderData['response_start'],
                                'response_end': FieldValue.serverTimestamp(),
                                'response_photo': urlDownload,
                              });

                              await FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(individualIncidentData['reported_by'])
                                  .collection("notifications")
                                  .add({
                                'title':
                                    "Incident No. ${incident_in_group} marked as Resolved",
                                'content':
                                    "You may send your feedback through the My Incidents section of the Profile Page so that we may be able to improve our service quality.",
                                'timestamp': FieldValue.serverTimestamp(),
                              });
                            }
                          }
                        }
                        Navigator.of(dialogContext).pop();
                        context.go('/tanod_home');
                        return;
                      }
                    }
                  }
                }
              }
            } else if (incidentData != null && incidentData['status'] != null) {
              if (incidentData['status'] == "Resolved" ||
                  incidentData['status'] == "Closed") {
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
                context.go('/tanod_home');
                return;
              } else {
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
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(reported_by)
                    .collection("notifications")
                    .add({
                  'title': "Incident No. ${widget.id} marked as Resolved",
                  'content':
                      "You may send your feedback through the My Incidents section of the Profile Page so that we may be able to improve our service quality.",
                  'timestamp': FieldValue.serverTimestamp(),
                });
                Navigator.of(dialogContext).pop();
                context.go('/tanod_home');
                return;
              }
            }
          }
        }
      }
      Navigator.of(dialogContext).pop();
      Utilities.showSnackBar("Something has gone wrong", Colors.red);
    } catch (ex) {
      Navigator.of(dialogContext).pop();
      Utilities.showSnackBar("$ex", Colors.red);
      return;
    }
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
                            incidentDetails['location_address'] ?? 'UNKNOWN',
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
                              "${incidentDetails['user_details']['first_name'] ?? 'UNKNOWN'} ${incidentDetails['user_details']['last_name'] ?? 'UNKNOWN'}",
                              style: CustomTextStyle.subheading,
                            ),
                            Text(
                              incidentDetails['user_details']['contact_no'] ??
                                  'UNKNOWN',
                              style: CustomTextStyle.regular_minor,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton.filled(
                              onPressed: () async {
                                await FlutterPhoneDirectCaller.callNumber(
                                    "${incidentDetails['user_details']['contact_no'] ?? 'UNKNOWN'}");
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
                      incidentDetails['title'] ?? 'UNKNOWN',
                      style: CustomTextStyle.subheading,
                    ),
                    Text(
                      Utilities.convertDate(
                          incidentDetails['timestamp'] ?? 'UNKNOWN'),
                      style: CustomTextStyle.regular_minor,
                    ),
                    Text(
                      incidentDetails['details'] ?? 'UNKNOWN',
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
                      function: () => endResponse(
                          incidentDetails['reported_by'] ?? 'UNKNOWN'),
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
