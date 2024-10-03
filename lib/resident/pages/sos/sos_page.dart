import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/models/user_model.dart';
import 'package:irs_app/widgets/input_button.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:maps_toolkit/maps_toolkit.dart' as map_tool;

class SosPage extends StatefulWidget {
  const SosPage({Key? key}) : super(key: key);

  @override
  _SosPageState createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> {
  File? recordedVideo;
  final picker = ImagePicker();
  final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();

  Future<bool> pickVideoFromCamera() async {
    final video = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: Duration(seconds: 30),
    );

    if (video == null) return false;

    recordedVideo = File(video.path);

    // Compress the video to 25MB or less
    final compressedVideoPath = await _compressVideo(recordedVideo!);

    if (compressedVideoPath != null) {
      recordedVideo = File(compressedVideoPath);
      return true;
    } else {
      print('Video compression failed');
      return false;
    }
  }

  Future<String?> _compressVideo(File videoFile) async {
    final Directory tempDir = await getTemporaryDirectory();

    final outputPath =
        '${tempDir.path}compressed_video.mp4'; // Set your output path

    // Use ffmpeg to compress the video with a target bitrate
    final int rc = await _flutterFFmpeg.execute(
        '-y -i ${videoFile.path} -vcodec h264 -b:v 500k -vf "scale=1280:-2" $outputPath');

    if (rc == 0) {
      print('Compression succeeded');
      return outputPath;
    } else {
      print('Compression failed with return code $rc');
      return null;
    }
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

  Future<void> sendAlertNotification() async {
    final url = Uri.parse(
        'https://us-central1-irs-capstone.cloudfunctions.net/sendSOSNotification');

    try {
      print("Running cloud function...");
      final response = await http.post(url);

      if (response.statusCode == 200) {
        print('Notification sent successfully');
      } else {
        print('Failed to send notification');
      }
    } catch (error) {
      print('Error: $error');
    }
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

    // if(!await checkIfEmergencyIsHandled(user_loc)){
    //   Navigator.pop(dialogContext);
    //   Utilities.showSnackBar("This incident is already being handled!", Colors.red);
    //   return;
    // }

    try {
      var urlDownload = "";

      if (recordedVideo != null) {
        // Generate a unique file name using UUID or timestamp
        String uniqueFileName = const Uuid()
            .v4(); // Or you can use DateTime.now().millisecondsSinceEpoch

        final path = '/sos_attachments/$uniqueFileName.mp4'; // Unique file path

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

      await sendAlertNotification();
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

  Future<bool> checkIfEmergencyIsHandled(LatLng location) async {
    Timestamp timestamp = Timestamp.now();
    final double RADIUS = 100; //in meters
    final int TIME_FRAME = 900000; // in miliseconds (15 minutes)

    final sosRef = FirebaseFirestore.instance.collection('sos');
    final sosTimestamp = timestamp.millisecondsSinceEpoch;
    final lowerTimeThreshold =
        DateTime.fromMillisecondsSinceEpoch(sosTimestamp - TIME_FRAME);
    final upperTimeThreshold =
        DateTime.fromMillisecondsSinceEpoch(sosTimestamp + TIME_FRAME);

    try {
      QuerySnapshot snapshot = await sosRef
          .where('timestamp', isGreaterThanOrEqualTo: lowerTimeThreshold)
          .where('timestamp', isLessThanOrEqualTo: upperTimeThreshold)
          .where('status',
              whereNotIn: ['Resolved', 'Closed', 'Dismissed']).get();

      print('Number of documents found: ${snapshot.docs.length}');

      List<Map<String, dynamic>> nearbySOSList = [];

      bool isHandled = false;

      for (var doc in snapshot.docs) {
        final docData = doc.data() as Map<String, dynamic>;
        final sosLocation = docData['location'];
        final sosStatus = docData['status'];

        double distance = Geolocator.distanceBetween(
          location.latitude,
          location.longitude,
          sosLocation['latitude'],
          sosLocation['longitude'],
        );

        if (distance <= RADIUS) {
          if (sosStatus == 'Handling') {
            isHandled = true;
            break;
          } else {
            nearbySOSList.add({
              'id': doc.id,
              ...docData,
              'distanceDiff': distance,
            });
          }
        }
      }

      print("Nearby incidents: $nearbySOSList");

      if (isHandled) {
        return false;
      } else {
        // setNearbyIncidents(nearbyIncidentsList);

        return true;
      }
    } catch (err) {
      print("Error fetching nearby incidents: $err");
      return false;
    }
  }

  List<LatLng> polygonPoints = [
    LatLng(14.969637, 120.917670),
    LatLng(14.964579, 120.921189),
    LatLng(14.967647, 120.927970),
    LatLng(14.961635, 120.930717),
    LatLng(14.962464, 120.932905),
    LatLng(14.967108, 120.931918),
    LatLng(14.971430, 120.932714),
    LatLng(14.972561, 120.932388),
    LatLng(14.973032, 120.933756),
    LatLng(14.978738, 120.931606),
    LatLng(14.974131, 120.925472),
    LatLng(14.974780, 120.924209),
    LatLng(14.973415, 120.923533),
    LatLng(14.974256, 120.922145),
    LatLng(14.969767, 120.919456),
    LatLng(14.970210, 120.918637),
    LatLng(14.969637, 120.917670),
  ];

  bool isInSelectedArea = false;
  LatLng user_loc = LatLng(14.970254, 120.925633);

  Future<bool> checkLocation(LatLng pointLatLng) async {
    return map_tool.PolygonUtil.containsLocation(
      map_tool.LatLng(pointLatLng.latitude, pointLatLng.longitude),
      polygonPoints
          .map((point) => map_tool.LatLng(point.latitude, point.longitude))
          .toList(),
      false,
    );
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

                                        _getCurrentLocation()
                                            .then((value) async {
                                          lat = "${value.latitude}";
                                          long = "${value.longitude}";

                                          if (!await checkLocation(LatLng(
                                              value.latitude,
                                              value.longitude))) {
                                            Utilities.showSnackBar(
                                                "You must be in the vicinity of Barangay Tambubong to report!",
                                                Colors.red);
                                            return;
                                          }
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
