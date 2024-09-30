import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:irs_app/core/utilities.dart';

class AdminMapScreen extends StatefulWidget {
  const AdminMapScreen({Key? key}) : super(key: key);

  @override
  _AdminMapScreenState createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
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

  Future<Uint8List> _getImageFromAssets(String assetPath) async {
    ByteData data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List();
  }

  Future<Set<Marker>> _getMarkers(QuerySnapshot incidents) async {
    Set<Marker> incidentsList = {};
    for (var incident in incidents.docs) {
      String myURL =
          "https://firebasestorage.googleapis.com/v0/b/irs-capstone.appspot.com/o/incident_tags_icons%2Fassault.png?alt=media&token=51fc633e-2cbb-4d18-b263-1d8c3cb82037";

      Uint8List bytes = await _getImageFromAssets('assets/sos_dot.png');
      final incidentWidget = Marker(
        markerId: MarkerId(incident.id),
        icon: BitmapDescriptor.fromBytes(bytes),
        position: LatLng(
          incident['location']['latitude'],
          incident['location']['longitude'],
        ),
        onTap: () {
          context.go('/admin_home/emergency/${incident.id}');
        },
      );
      incidentsList.add(incidentWidget);
    }
    return incidentsList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Map"),
      ),
      body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('sos')
              .where('status', whereIn: ['Active', 'Handling']).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return FutureBuilder(
                future: _getMarkers(snapshot.data!),
                builder: (context, snapshot) {
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
                    markers: snapshot.data!,
                  );
                },
              );
            } else {
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
              );
            }
          }),
    );
  }
}
