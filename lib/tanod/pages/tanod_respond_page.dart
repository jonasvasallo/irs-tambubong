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
import 'package:irs_app/tanod/pages/emergency_respond_section.dart';
import 'package:irs_app/tanod/pages/incident_respond_section.dart';
import 'package:irs_app/widgets/input_button.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:location/location.dart' as loc;
import 'package:url_launcher/url_launcher.dart';

class TanodRespondPage extends StatefulWidget {
  final String id;
  final double latitude;
  final double longitude;
  final String type;
  const TanodRespondPage(
      {Key? key,
      required this.id,
      required this.latitude,
      required this.longitude,
      required this.type})
      : super(key: key);

  @override
  _TanodRespondPageState createState() => _TanodRespondPageState();
}

class _TanodRespondPageState extends State<TanodRespondPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Responding"),
        leading: SizedBox(),
      ),
      body: SlidingUpPanel(
        backdropEnabled: true,
        borderRadius: BorderRadius.circular(16),
        panel: (widget.type == "incident")
            ? IncidentRespondSection(id: widget.id)
            : EmergencyRespondSection(id: widget.id),
        body: GoogleMapsSection(
          latitude: widget.latitude,
          longitude: widget.longitude,
        ),
      ),
    );
  }
}

class GoogleMapsSection extends StatefulWidget {
  final double latitude;
  final double longitude;
  const GoogleMapsSection(
      {Key? key, required this.latitude, required this.longitude})
      : super(key: key);

  @override
  _GoogleMapsSectionState createState() => _GoogleMapsSectionState();
}

class _GoogleMapsSectionState extends State<GoogleMapsSection> {
  final Completer<GoogleMapController> _controller = Completer();

  static const LatLng sourceLocation = LatLng(14.967494, 120.920238);

  LatLng? destinationLocation;

  List<LatLng> polylineCoordinates = [];
  Position? currentLocation;
  late StreamSubscription<Position> _positionStreamSubscription;

  Future<Position> getCurrentLocation() async {
    print("get location was called");
    Geolocator geolocator = Geolocator();

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

    print("success permission");

    GoogleMapController googleMapController = await _controller.future;

    return await Geolocator.getCurrentPosition(
        forceAndroidLocationManager: true);

    // Geolocator.getPositionStream().listen((newLoc) {
    //   currentLocation = newLoc;
    //   googleMapController.animateCamera(CameraUpdate.newCameraPosition(
    //       CameraPosition(
    //           zoom: 13.5, target: LatLng(newLoc.latitude, newLoc.longitude))));
    //   setState(() {});
    // });
  }

  void _getCurrentLocation() async {
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
      currentLocation = value;

      // getPolyPoints();
    });

    // GoogleMapController googleMapController = await _controller.future;

    _positionStreamSubscription =
        await Geolocator.getPositionStream().listen((event) {
      currentLocation = event;
      // googleMapController.animateCamera(CameraUpdate.newCameraPosition(
      //     CameraPosition(
      //         zoom: 13.5, target: LatLng(event.latitude, event.longitude))));
      setState(() {});
    });
  }

  void getPolyPoints() async {
    print("function called");
    print("latitude: ${currentLocation!.latitude}");
    PolylinePoints polylinePoints = PolylinePoints();

    try {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        apiKey,
        PointLatLng(currentLocation!.latitude, currentLocation!.longitude),
        PointLatLng(
            destinationLocation!.latitude, destinationLocation!.longitude),
      );
      if (result.points.isNotEmpty) {
        result.points.forEach(
          (PointLatLng point) => polylineCoordinates.add(
            LatLng(
              point.latitude,
              point.longitude,
            ),
          ),
        );
        setState(() {});
        print("function worked");
      }
    } catch (err) {
      print(err);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    destinationLocation = LatLng(widget.latitude, widget.longitude);
    // getCurrentLocation().then((value) {
    //   setState(() {
    //     currentLocation = value;
    //     print(currentLocation!
    //         .latitude); // Update the state with the retrieved location
    //   });
    // }).catchError((error) {
    //   print('Error getting current location: $error');
    // });
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription.cancel();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    return currentLocation == null
        ? Center(
            child: CircularProgressIndicator(),
          )
        : GoogleMap(
            zoomControlsEnabled: false,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                currentLocation!.latitude!,
                currentLocation!.longitude!,
              ),
              zoom: 15,
            ),
            polylines: {
              Polyline(
                polylineId: PolylineId('route'),
                points: polylineCoordinates,
                color: accentColor,
                width: 6,
              ),
            },
            markers: {
              Marker(
                markerId: MarkerId('currentLocation'),
                position: LatLng(
                    currentLocation!.latitude!, currentLocation!.longitude!),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen),
              ),
              Marker(
                markerId: MarkerId("destination"),
                position: destinationLocation!,
                icon: BitmapDescriptor.defaultMarker,
              ),
            },
          );
  }
}
