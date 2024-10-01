import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/models/user_model.dart';
import 'package:irs_app/widgets/incident_container.dart';
import 'package:irs_app/widgets/input_button.dart';

import 'package:http/http.dart' as http;
import 'package:location/location.dart';

class TanodHomePage extends StatefulWidget {
  const TanodHomePage({Key? key}) : super(key: key);

  @override
  _TanodHomePageState createState() => _TanodHomePageState();
}

class _TanodHomePageState extends State<TanodHomePage> {
  Location location = new Location();

  StreamSubscription<LocationData>? locationSubscription;

  UserModel model = new UserModel();
  bool onDuty = false;

  void fetchIsOnline() async {
    Map<String, dynamic>? userDetails = await UserModel.getUserById(model.uId);
    if (userDetails != null) {
      setState(() {
        onDuty = userDetails['isOnline'] ?? false;
      });
    } else {
      print('User details not found');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchIsOnline();
    if (onDuty) {
      print("this happened");
      _subscribeToLocationChanges();
    }
  }

  void updateTanodLocation(LatLng new_loc) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        'current_location': {
          'latitude': new_loc.latitude,
          'longitude': new_loc.longitude,
        },
      });
      print("updated tanod location");
    } catch (err) {
      print(err);
    }
  }

  void _subscribeToLocationChanges() async {
    print("function called");
    if (!await getLocationPermissions()) return;

    location.changeSettings(interval: 15000, distanceFilter: 10);
    location.enableBackgroundMode(enable: true);
    locationSubscription =
        location.onLocationChanged.listen((LocationData currentLocation) {
      print(
          "Location changed: ${currentLocation.latitude}, ${currentLocation.longitude}");
      if (currentLocation.latitude != null ||
          currentLocation.longitude != null) {
        updateTanodLocation(
            LatLng(currentLocation.latitude!, currentLocation.longitude!));
      }
    });
  }

  Future<bool> getLocationPermissions() async {
    print("permissions called");
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return false;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }

  void goOnline() async {
    try {
      CollectionReference users = FirebaseFirestore.instance.collection(
        'users',
      );

      await users.doc(FirebaseAuth.instance.currentUser!.uid).update({
        'isOnline': true,
      });
      setState(() {
        onDuty = true;
        _subscribeToLocationChanges();
      });
      Utilities.showSnackBar("Went online", Colors.green);
    } catch (ex) {
      Utilities.showSnackBar("${ex}", Colors.red);
    }
  }

  void goOffline() async {
    try {
      CollectionReference users = FirebaseFirestore.instance.collection(
        'users',
      );

      await users.doc(FirebaseAuth.instance.currentUser!.uid).update({
        'isOnline': false,
      });
      setState(() {
        onDuty = false;
        if (locationSubscription != null) {
          locationSubscription!.cancel();
        }
      });
      Utilities.showSnackBar("Went offline", Colors.green);
    } catch (ex) {
      Utilities.showSnackBar("${ex}", Colors.red);
    }
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

  @override
  void dispose() {
    if (locationSubscription != null) {
      locationSubscription!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            FutureBuilder(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .get(),
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

                  final userDetails = snapshot.data!;

                  return UserAccountsDrawerHeader(
                    currentAccountPicture: CircleAvatar(
                      backgroundImage:
                          NetworkImage(userDetails['profile_path']),
                    ),
                    accountName: Text(
                        "${userDetails['first_name']} ${userDetails['last_name']}"),
                    accountEmail: Text("${userDetails['email']}"),
                  );
                }),
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text("Profile"),
              onTap: () {
                context.go('/tanod_home/profile');
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text("Response History"),
              onTap: () {
                context.go('/tanod_home/response-history');
              },
            ),
            ListTile(
              leading: Icon(Icons.logout_outlined),
              title: Text("Logout"),
              onTap: () {
                FirebaseMessaging.instance.unsubscribeFromTopic('incident-alert');
                FirebaseMessaging.instance.unsubscribeFromTopic('sos-alert');
                FirebaseAuth.instance.signOut();
                context.go('/login');
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text("Incidents"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: (!onDuty)
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "You are offline!",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "You will not be able to receive incidents or emergencies. Click the Go Online button below to start receiving response requests.",
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey,
                      child: Image.asset(
                        "assets/x_mark.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    InputButton(
                      label: "Go Online",
                      function: () {
                        goOnline();
                      },
                      large: true,
                    ),
                  ],
                )
              : Column(
                  children: [
                    InputButton(
                      label: "Go Offline",
                      function: () {
                        goOffline();
                      },
                      large: true,
                    ),
                    FutureBuilder(
                      future: fetchWorldTime(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator(); // Placeholder for loading state
                        }
                        if (snapshot.hasError) {
                          return Text(
                              'Could not validate time. Please check your internet connection or try restarting the app. Error Message: (${snapshot.error})'); // Placeholder for error state
                        }

                        final worldTime = snapshot.data as DateTime;
                        final sixPM = DateTime(worldTime.year, worldTime.month,
                            worldTime.day, 18, 0);

                        Query query = FirebaseFirestore.instance
                            .collection('sos')
                            .where('status', whereNotIn: [
                          'Closed',
                          'Resolved',
                          'Dismissed',
                          'Cancelled',
                        ]);

                        if (worldTime.isBefore(sixPM)) {
                          print("it is before 6 pm");
                          query = query.where('responders',
                              arrayContains:
                                  FirebaseAuth.instance.currentUser!.uid);
                        }
                        return StreamBuilder(
                          stream: query.snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator(); // Placeholder for loading state
                            }
                            if (snapshot.hasError) {
                              print("${snapshot.error}");
                              return Text(
                                  'Error: ${snapshot.error}'); // Placeholder for error state
                            }
                            final docs = snapshot.data?.docs ?? [];
                            return Column(
                              children: docs.map((doc) {
                                return GestureDetector(
                                  onTap: () {
                                    context.go(
                                        '/tanod_home/emergency-details/${doc.id}');
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 8, bottom: 8),
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color:
                                            Color.fromARGB(255, 248, 246, 246),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.red, width: 1),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Flexible(
                                                  flex: 3,
                                                  child: Text(
                                                    "INCOMING SOS",
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: Colors
                                                          .redAccent.shade700,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  Utilities.convertDate(
                                                      doc['timestamp']),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style:
                                                      CustomTextStyle.regular,
                                                ),
                                              ],
                                            ),
                                            FutureBuilder(
                                                future: FirebaseFirestore
                                                    .instance
                                                    .collection('users')
                                                    .doc(doc['user_id'])
                                                    .get(),
                                                builder: (context, snapshot) {
                                                  if (snapshot
                                                          .connectionState ==
                                                      ConnectionState.waiting) {
                                                    return CircularProgressIndicator(); // Placeholder for loading state
                                                  }
                                                  if (snapshot.hasError) {
                                                    print("${snapshot.error}");
                                                    return Text(
                                                        'Error: ${snapshot.error}'); // Placeholder for error state
                                                  }
                                                  final userData =
                                                      snapshot.data?.data();
                                                  final firstName =
                                                      userData?['first_name'] ??
                                                          'N/A';
                                                  final lastName =
                                                      userData?['last_name'] ??
                                                          'N/A';
                                                  return Text(
                                                    "from: ${firstName} ${lastName}",
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style:
                                                        CustomTextStyle.regular,
                                                  );
                                                }),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        );
                      },
                    ),
                    FutureBuilder(
                      future: fetchWorldTime(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator(); // Placeholder for loading state
                        }
                        if (snapshot.hasError) {
                          print("${snapshot.error}");
                          return Text(
                              'Error: ${snapshot.error}'); // Placeholder for error state
                        }

                        final worldTime = snapshot.data as DateTime;
                        final sixPM = DateTime(worldTime.year, worldTime.month,
                            worldTime.day, 18, 0);

                        // Query for the 'incidents' collection
                        Query incidentsQuery = FirebaseFirestore.instance
                            .collection('incidents')
                            .where('status',
                                whereNotIn: ['Resolved', 'Closed', 'Rejected']);

                        if (worldTime.isBefore(sixPM)) {
                          print("it is before 6 pm");
                          incidentsQuery = incidentsQuery.where('responders',
                              arrayContains:
                                  FirebaseAuth.instance.currentUser!.uid);
                        }

                        return StreamBuilder(
                          stream: incidentsQuery.snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator(); // Placeholder for loading state
                            }
                            if (snapshot.hasError) {
                              print("${snapshot.error}");
                              return Text(
                                  'Error: ${snapshot.error}'); // Placeholder for error state
                            }
                            final docs = snapshot.data?.docs ?? [];
                            return Column(
                              children: docs.map((doc) {
                                return GestureDetector(
                                  onTap: () {
                                    context.go(
                                        '/tanod_home/incident-details/${doc.id}');
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 8, bottom: 8),
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color:
                                            Color.fromARGB(255, 248, 246, 246),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: minorText, width: 1),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Flexible(
                                                  flex: 3,
                                                  child: Text(
                                                    doc['title'],
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: CustomTextStyle
                                                        .subheading,
                                                  ),
                                                ),
                                                Text(
                                                  Utilities.convertDate(
                                                      doc['timestamp']),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style:
                                                      CustomTextStyle.regular,
                                                ),
                                              ],
                                            ),
                                            Text(
                                              doc['details'],
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  CustomTextStyle.regular_minor,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
