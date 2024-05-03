import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:irs_capstone/constants.dart';
import 'package:irs_capstone/core/utilities.dart';
import 'package:irs_capstone/widgets/input_button.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:location/location.dart' as loc;
import 'package:url_launcher/url_launcher.dart';

class TanodRespondPage extends StatefulWidget {
  final String id;
  final double latitude;
  final double longitude;
  const TanodRespondPage(
      {Key? key,
      required this.id,
      required this.latitude,
      required this.longitude})
      : super(key: key);

  @override
  _TanodRespondPageState createState() => _TanodRespondPageState();
}

class _TanodRespondPageState extends State<TanodRespondPage> {
  /*
  final Completer<GoogleMapController?> _controller = Completer();
  Map<PolylineId, Polyline> polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();
  loc.Location location = loc.Location();
  Marker? sourcePosition, destinationPosition;
  loc.LocationData? _currentPosition;
  LatLng curLocation = LatLng(14.9690824, 120.9244701);
  StreamSubscription<loc.LocationData>? locationSubscription;

  addMarker() {
    setState(() {
      sourcePosition = Marker(
        markerId: MarkerId('source'),
        position: curLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
      destinationPosition = Marker(
        markerId: MarkerId('destination'),
        position: LatLng(widget.latitude, widget.longitude),
        icon: BitmapDescriptor.defaultMarker,
      );
    });
  }

  getNavigation() async {
    try {
      bool _serviceEnabled;
      loc.PermissionStatus _permissionGranted;
      final GoogleMapController? controller = await _controller.future;
      location.changeSettings(accuracy: loc.LocationAccuracy.high);
      _serviceEnabled = await location.serviceEnabled();

      if (!_serviceEnabled) {
        _serviceEnabled = await location.requestService();
        if (!_serviceEnabled) {
          return;
        }
      }

      _permissionGranted = await location.hasPermission();
      if (_permissionGranted == loc.PermissionStatus.denied) {
        _permissionGranted = await location.requestPermission();
        if (_permissionGranted != loc.PermissionStatus.granted) {
          return;
        }
      }

      if (_permissionGranted == loc.PermissionStatus.granted) {
        print('permissionn working');
        _currentPosition = await location.getLocation();
        curLocation =
            LatLng(_currentPosition!.latitude!, _currentPosition!.longitude!);
        locationSubscription = location.onLocationChanged
            .listen((loc.LocationData currentLocation) {
          controller?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(
                    currentLocation.latitude!, currentLocation.longitude!),
                zoom: 16,
              ),
            ),
          );
          if (mounted) {
            controller?.showMarkerInfoWindow(
                MarkerId(sourcePosition!.markerId.value));
            setState(() {
              curLocation =
                  LatLng(currentLocation.latitude!, currentLocation.longitude!);
              sourcePosition = Marker(
                markerId: MarkerId(currentLocation.toString()),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure),
                position: LatLng(
                    currentLocation.latitude!, currentLocation.longitude!),
                infoWindow: InfoWindow(),
                onTap: () {
                  print("marker tapped");
                },
              );
            });
            getDirections(LatLng(widget.latitude, widget.longitude));
          }
        });
      }
    } catch (err) {
      print(err);
    }
  }

  getDirections(LatLng dst) async {
    List<LatLng> polylineCoordinates = [];
    List<dynamic> points = [];

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        '',
        PointLatLng(curLocation.latitude, curLocation.longitude),
        PointLatLng(dst.latitude, dst.longitude),
        travelMode: TravelMode.driving);
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        points.add({'lat': point.latitude, 'lng': point.longitude});
      });
    } else {
      print(result.errorMessage);
    }
    addPolyline(polylineCoordinates);
  }

  addPolyline(List<LatLng> polylineCoordinates) {
    PolylineId id = PolylineId('poly');
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 3,
    );
    polylines[id] = polyline;
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState

    super.initState();
    getNavigation();
    addMarker();
  }
  */

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Responding"),
      ),
      body: SlidingUpPanel(
        backdropEnabled: true,
        borderRadius: BorderRadius.circular(16),
        panel: FutureBuilder(
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
                                      // await launchUrl(
                                      //   Uri.parse(
                                      //       'https://www.google.com/maps/dir/api=1&destination=${widget.latitude},${widget.longitude}'),
                                      //   mode: LaunchMode.externalApplication,
                                      // );
                                      await launchUrl(Uri.parse(
                                          "https://www.google.com/maps/dir/14.9744688,120.9428094/14.9675565,120.9234425/@14.9698574,120.9302176,16z?entry=ttu"));
                                    },
                                    icon: Icon(
                                      Icons.navigation_outlined,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {},
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
                                    incidentDetails['user_details']
                                        ['contact_no'],
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
                              onPressed: () {},
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
                          SizedBox(
                            height: 16,
                          ),
                          InputButton(
                            label: "End Response",
                            function: () {},
                            large: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
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

      getPolyPoints();
    });

    // GoogleMapController googleMapController = await _controller.future;

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
