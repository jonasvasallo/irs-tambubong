import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:irs_capstone/constants.dart';
import 'package:irs_capstone/core/input_validator.dart';
import 'package:irs_capstone/core/utilities.dart';
import 'package:irs_capstone/widgets/input_button.dart';
import 'package:irs_capstone/widgets/input_field.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as map_tool;

class AddIncidentPage extends StatefulWidget {
  const AddIncidentPage({Key? key}) : super(key: key);

  @override
  _AddIncidentPageState createState() => _AddIncidentPageState();
}

class _AddIncidentPageState extends State<AddIncidentPage> {
  final formKey = GlobalKey<FormState>();
  late StreamController<List<Map<String, dynamic>>> _tagsStreamController;
  late List<Map<String, dynamic>> _incidentTags;

  late LatLng _center = LatLng(14.970254, 120.925633);

  LatLng user_loc = LatLng(14.970254, 120.925633);

  bool isInSelectedArea = false;

  String address_str = "";

  Future<Position> getCurrentLocation() async {
    /*
    This function gets the current location of the device of the user
    It first checks if the app has access/permission to the location service
    After confirming, it will return the position of the device
  */

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return Future.error('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request');
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  void initState() {
    super.initState();

    _tagsStreamController = StreamController<List<Map<String, dynamic>>>();
    _incidentTags = [];

    // Fetch incident tags when the widget is initialized
    getIncidentTags().then((tags) {
      _tagsStreamController.add(tags);
    });
  }

  final titleController = TextEditingController();
  final detailsController = TextEditingController();

  var _dropdownValue = "";

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> get tagsStream =>
      _tagsStreamController.stream;

  Future<List<Map<String, dynamic>>> getIncidentTags() async {
    List<Map<String, dynamic>> incidentTags = [];

    try {
      QuerySnapshot tagsSnapshot =
          await FirebaseFirestore.instance.collection('incident_tags').get();

      if (tagsSnapshot.docs.isNotEmpty) {
        for (var tagDocument in tagsSnapshot.docs) {
          Map<String, dynamic> tagData =
              tagDocument.data() as Map<String, dynamic>;
          incidentTags.add({
            'tag_id': tagDocument.id,
            'tag_name': tagData['tag_name'],
            // Add more fields if needed
          });
        }
      } else {
        print('No tags found in the incident_tags collection.');
      }
    } catch (ex) {
      print('Error fetching incident tags: $ex');
    }

    return incidentTags;
  }

  late GoogleMapController mapController;

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

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  /* Attach Multiple Photos */
  List<Widget> media_photos = [];
  int imageCounts = 0;

  String selectFile = "";
  List<Uint8List> pickedImagesInBytes = [];

  _selectFile(bool imageFrom) async {
    FilePickerResult? fileResult = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: true,
      type: FileType.image,
    );

    if (fileResult != null) {
      setState(() {
        selectFile = fileResult.files.first.name;
        fileResult.files.forEach((element) {
          setState(() {
            pickedImagesInBytes.add(element.bytes!);
            media_photos.add(
              Padding(
                padding: const EdgeInsets.only(right: 8, left: 8),
                child: Container(
                  width: 300,
                  height: 150,
                  color: Colors.black,
                  child: Image.memory(element.bytes!),
                ),
              ),
            );
            imageCounts++;
          });
        });
      });
    } else {
      print("test");
    }
    print(selectFile);
  }

  Future<List<String>> _uploadMultipleFiles(String itemName) async {
    List<String> imageUrls = [];
    String imageUrl = "";
    try {
      for (var i = 0; i < imageCounts; i++) {
        UploadTask uploadTask;

        Reference ref = FirebaseStorage.instance
            .ref()
            .child('incident_attachments/${itemName}_$i');

        final metadata = SettableMetadata(contentType: 'image/jpeg');

        uploadTask = ref.putData(pickedImagesInBytes[i], metadata);
        await uploadTask.whenComplete(() => null);
        imageUrl = await ref.getDownloadURL();
        imageUrls.add(imageUrl);
      }

      return imageUrls;
    } catch (ex) {
      print('Error uploading image to Firestore: $ex');
      throw ex;
    }
  }

  void checkLocation(LatLng pointLatLng) async {
    setState(() async {
      isInSelectedArea = map_tool.PolygonUtil.containsLocation(
        map_tool.LatLng(pointLatLng.latitude, pointLatLng.longitude),
        polygonPoints
            .map((point) => map_tool.LatLng(point.latitude, point.longitude))
            .toList(),
        false,
      );
    });
  }

  Future<String> getLocationAddress(LatLng pointLatLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          pointLatLng.latitude, pointLatLng.longitude);

      Placemark place = placemarks[0];
      return "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}";
    } catch (ex) {
      print(ex);
    }
    return "";
  }

  void addIncident() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (_dropdownValue.isEmpty) {
      Utilities.showSnackBar("Choose an incident tag", Colors.red);
      return;
    }

    checkLocation(user_loc);
    print(user_loc);
    print(isInSelectedArea);
    // if (!isInSelectedArea) {
    //   Utilities.showSnackBar(
    //     "You are not within the boundaries of Brgy. Tambubong!",
    //     Colors.red,
    //   );
    //   return;
    // }

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
      List<String> imageUrls = [];
      if (pickedImagesInBytes.length > 0) {
        print("working?");
        imageUrls = await _uploadMultipleFiles(
            "${FirebaseAuth.instance.currentUser?.uid}${titleController.text}_incident_media");
      }

      CollectionReference incidentsCollection =
          FirebaseFirestore.instance.collection('incidents');

      final address = await getLocationAddress(user_loc);

      final DocumentReference newDocumentRef = await incidentsCollection.add({
        'title': titleController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Verified',
        'responders': [],
        'reported_by': FirebaseAuth.instance.currentUser?.uid,
        'media_attachments': imageUrls,
        'location_address': address,
        'incident_tag': _dropdownValue,
        'details': detailsController.text.trim(),
        'coordinates': {
          'latitude': user_loc.latitude,
          'longitude': user_loc.longitude,
        }
      });

      Utilities.showSnackBar("Successfully posted incident", Colors.green);
      Navigator.pop(dialogContext);
      context.go("/home/incident/${newDocumentRef.id}");
    } catch (ex) {
      Utilities.showSnackBar("$ex", Colors.red);
      Navigator.pop(dialogContext);
      print(ex);
    }
  }

  // void postNews() async {
  //   InputValidator.checkFormValidity(formKey, context);

  //   try {
  //     List<String> imageUrls = [];
  //     if (pickedImagesInBytes.length > 0) {
  //       imageUrls = await _uploadMultipleFiles("${FirebaseAuth.instance.currentUser?.uid}${_headingController.text}_news_media");
  //     }
  //     CollectionReference newsCollection =
  //         FirebaseFirestore.instance.collection('news');

  //     await newsCollection.add({
  //       'heading': _headingController.text.trim(),
  //       'body': _bodyController.text.trim(),
  //       'timestamp': FieldValue.serverTimestamp(),
  //       'media_attachments': imageUrls,
  //       'posted_by': FirebaseAuth.instance.currentUser?.uid,
  //     });
  //     Utilities.showSnackBar("Successfully posted", Colors.green);
  //     setState(() {
  //       _headingController.text = "";
  //       _bodyController.text = "";
  //       selectFile = "";
  //       imageCounts = 0;
  //       media_photos.clear();
  //       pickedImagesInBytes.clear();
  //     });
  //   } catch (ex) {
  //     Utilities.showSnackBar("$ex", Colors.red);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Incident"),
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                FutureBuilder(
                    future: getCurrentLocation(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      Position center = snapshot.data!;
                      LatLng position =
                          LatLng(center.latitude, center.longitude);

                      user_loc = position;

                      return Container(
                        height: 200,
                        width: MediaQuery.of(context).size.width,
                        color: Colors.grey,
                        child: GoogleMap(
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: true,
                          initialCameraPosition: CameraPosition(
                            target: position,
                            zoom: 17,
                          ),
                          polygons: {
                            Polygon(
                              polygonId: PolygonId("1"),
                              points: polygonPoints,
                              fillColor: Color(0xFF006491).withOpacity(0.2),
                              strokeWidth: 2,
                            )
                          },
                          markers: {
                            Marker(
                              markerId: MarkerId('1'),
                              icon: BitmapDescriptor.defaultMarker,
                              position: position,
                            ),
                          },
                        ),
                      );
                    }),
                SizedBox(
                  height: 16,
                ),
                InputField(
                  placeholder: "Incident Title",
                  inputType: "text",
                  controller: titleController,
                  label: "Incident Title",
                  validator: InputValidator.requiredValidator,
                ),
                InputField(
                  placeholder: "Incident Details",
                  inputType: "message",
                  controller: detailsController,
                  label: "Incident Details",
                  validator: InputValidator.requiredValidator,
                ),
                StreamBuilder(
                  stream: tagsStream,
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
                      _incidentTags = snapshot.data!;

                      return DropdownMenu(
                        hintText: "Choose Incident Tag",
                        width: MediaQuery.of(context).size.width - 32,
                        onSelected: (value) {
                          _dropdownValue = value;
                          print(_dropdownValue);
                        },
                        dropdownMenuEntries:
                            _incidentTags.map((Map<String, dynamic> tag) {
                          return DropdownMenuEntry(
                              value: tag['tag_id'], label: tag['tag_name']);
                        }).toList(),
                      );
                    }
                  },
                ),
                SizedBox(
                  height: 16,
                ),
                TextButton(
                  onPressed: () {
                    _selectFile(true);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo,
                        size: 32,
                      ),
                      SizedBox(
                        width: 8,
                      ),
                      Text(
                        "Attach Media",
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: 16,
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: media_photos,
                  ),
                ),
                SizedBox(
                  height: 16,
                ),
                InputButton(
                  label: "Submit Incident",
                  function: () {
                    addIncident();
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
