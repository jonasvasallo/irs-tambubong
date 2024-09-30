import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:irs_app/app_router.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/models/firebase_api.dart';
import 'package:irs_app/models/user_model.dart';
import 'package:irs_app/widgets/incident_container.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image/image.dart' as img;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(14.9690824, 120.9244701);

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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    checkUserType();
    subscribeToTopic();
  }

  void subscribeToTopic() async {
    UserModel model = UserModel();
    if (FirebaseAuth.instance.currentUser == null) {
      return;
    }
    await model.updateFCMToken(
      FirebaseAuth.instance.currentUser!.uid,
      await FirebaseApi().initNotifications() ?? '',
    );
  }

  void checkUserType() async {
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get();

    if (documentSnapshot.exists) {
      Map<String, dynamic> userDetails =
          documentSnapshot.data() as Map<String, dynamic>;
      if (userDetails['disabled'] == true) {
        Utilities.showSnackBar(
          "Your account has been restricted from accessing the app.",
          Colors.red,
        );
        FirebaseAuth.instance.signOut();
        context.go('/login');
        return;
      }
      if (userDetails['user_type'] == 'resident') {
        AppRouter.initR = "/home";
      } else if (userDetails['user_type'] == 'moderator' ||
          userDetails['user_type'] == 'admin') {
        AppRouter.initR = "/admin_home";
        context.go("/admin_home");
      } else {
        AppRouter.initR = "/tanod_home";
        context.go('/tanod_home');
      }
    } else {
      context.go('/login');
    }
  }

  Future<Uint8List> _getImageFromNetwork(imageUrl) async {
    Uint8List bytes =
        (await NetworkAssetBundle(Uri.parse(imageUrl)).load(imageUrl))
            .buffer
            .asUint8List();

    // Decode the image
    img.Image? image = img.decodeImage(bytes);
    if (image != null) {
      // Resize the image
      img.Image resized = img.copyResize(image, width: 200, height: 200);

      // Encode the image to Uint8List
      Uint8List resizedBytes = Uint8List.fromList(img.encodePng(resized));
      return resizedBytes;
    }

    return bytes;
  }

  Future<Set<Marker>> _getMarkers(QuerySnapshot incidents) async {
    Set<Marker> incidentsList = {};
    for (var incident in incidents.docs) {
      if (incident['status'] == 'Verifying') {
        continue;
      }
      final incidentTagSnapshot = await FirebaseFirestore.instance
          .collection('incident_tags')
          .doc(incident['incident_tag'])
          .get();

      String myURL = "";
      if (incidentTagSnapshot.exists) {
        final incidentTagData =
            incidentTagSnapshot.data() as Map<String, dynamic>;
        myURL = incidentTagData['tag_image'];
      } else {
        myURL =
            "https://firebasestorage.googleapis.com/v0/b/irs-capstone.appspot.com/o/incident_tags_icons%2Fassault.png?alt=media&token=51fc633e-2cbb-4d18-b263-1d8c3cb82037";
      }
      Uint8List bytes = await _getImageFromNetwork(myURL);
      final incidentWidget = Marker(
        markerId: MarkerId(incident.id),
        icon: BitmapDescriptor.fromBytes(bytes),
        position: LatLng(
          incident['coordinates']['latitude'],
          incident['coordinates']['longitude'],
        ),
        onTap: () {
          context.go('/home/incident/${incident.id}');
        },
      );
      incidentsList.add(incidentWidget);
    }
    return incidentsList;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(Duration(days: 7));
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.go('/home/add-incident');
          },
          backgroundColor: accentColor,
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
        body: SlidingUpPanel(
          backdropEnabled: true,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          panel: Padding(
            padding: padding16,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    "Recent Incidents",
                    style: CustomTextStyle.subheading,
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('incidents')
                        .where(
                          'timestamp',
                          isGreaterThanOrEqualTo:
                              Timestamp.fromDate(oneWeekAgo),
                        )
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      List<Widget> incidentsList = [];
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        print("No incidents found or snapshot has no data");
                        return Text("No incidents yet.");
                      }
                      final incidents = snapshot.data!.docs.toList();
                      for (int i = 0; i < incidents.length; i++) {
                        print("fetching incidents");
                        var incident = incidents[i];
                        String myDate = "test";
                        bool isLatest = i == 0;

                        if (incident['status'] == 'Verifying' ||
                            incident['status'] == 'Rejected') {
                          print("found incident with verifying status");
                          continue;
                        }

                        if (incident['timestamp'] != null) {
                          Timestamp t = incident['timestamp'] as Timestamp;
                          DateTime date = t.toDate();
                          myDate = DateFormat('MM/dd hh:mm').format(date);
                          myDate = timeago.format(date);
                        }

                        final incidentWidget = FutureBuilder(
                          future: FirebaseFirestore.instance
                              .collection('incidents')
                              .doc(incident.id)
                              .collection('witnesses')
                              .get(),
                          builder: (context, futureSnapshot) {
                            if (!futureSnapshot.hasData) {
                              return IncidentContainer(
                                title: incident['title'],
                                location: incident['location_address'],
                                details: incident['details'],
                                date: myDate,
                                id: incident.id,
                                latest: isLatest,
                                witnesses: 0, // Default value while loading
                              );
                            }

                            int witnessCount = futureSnapshot.data!.docs.length;

                            return IncidentContainer(
                              title: incident['title'],
                              location: incident['location_address'],
                              details: incident['details'],
                              date: myDate,
                              id: incident.id,
                              latest: isLatest,
                              witnesses: witnessCount,
                            );
                          },
                        );
                        incidentsList.add(incidentWidget);
                      }
                      return Column(
                        children: incidentsList,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          body: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('incidents')
                  .where('timestamp',
                      isGreaterThanOrEqualTo: Timestamp.fromDate(oneWeekAgo))
                  .where('status',
                      whereNotIn: ['Rejected', 'Verifying']).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return FutureBuilder<Set<Marker>>(
                    future: _getMarkers(snapshot.data!),
                    builder: (context, markersSnapshot) {
                      if (!markersSnapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      return GoogleMap(
                        myLocationButtonEnabled: false,
                        initialCameraPosition: CameraPosition(
                          target: LatLng(14.970254, 120.925633),
                          zoom: 15,
                        ),
                        polygons: {
                          Polygon(
                            polygonId: PolygonId("1"),
                            points: polygonPoints,
                            fillColor: Color(0xFF006491).withOpacity(0.2),
                            strokeWidth: 2,
                          )
                        },
                        markers: markersSnapshot.data!,
                      );
                    },
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              }),
        ));
  }
}
