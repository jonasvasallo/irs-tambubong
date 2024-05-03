import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:irs_capstone/app_router.dart';
import 'package:irs_capstone/constants.dart';

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
  }

  void checkUserType() async {
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get();

    if (documentSnapshot.exists) {
      Map<String, dynamic> userDetails =
          documentSnapshot.data() as Map<String, dynamic>;

      if (userDetails['user_type'] == 'resident') {
        AppRouter.initR = "/home";
      } else {
        AppRouter.initR = "/tanod_home";
        context.go('/tanod_home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: StreamBuilder(
          stream:
              FirebaseFirestore.instance.collection('incidents').snapshots(),
          builder: (context, snapshot) {
            Set<Marker> incidentsList = {};
            if (!snapshot.hasData) {
              return Text("No Data");
            }
            final incidents = snapshot.data?.docs.toList();
            for (var incident in incidents!) {
              final incidentWidget = Marker(
                markerId: MarkerId(incident.id),
                icon: BitmapDescriptor.defaultMarker,
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
              markers: incidentsList,
            );
          }),
    );
  }
}
