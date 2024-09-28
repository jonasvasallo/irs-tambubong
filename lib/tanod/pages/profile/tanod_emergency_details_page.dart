import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart";
import "package:go_router/go_router.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "package:irs_app/constants.dart";
import "package:irs_app/core/utilities.dart";
import "package:irs_app/widgets/input_button.dart";

class TanodEmergencyDetailsPage extends StatefulWidget {
  final String id;
  const TanodEmergencyDetailsPage({Key? key, required this.id})
      : super(key: key);

  @override
  _TanodEmergencyDetailsPageState createState() =>
      _TanodEmergencyDetailsPageState();
}

class _TanodEmergencyDetailsPageState extends State<TanodEmergencyDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Emergency Details"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: padding16,
          child: FutureBuilder(
              future: FirebaseFirestore.instance
                  .collection("sos")
                  .doc(widget.id)
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

                final emergencyDetails = snapshot.data!.data();

                return Column(
                  children: [
                    Container(
                      width: MediaQuery.sizeOf(context).width - 32,
                      height: 250,
                      color: Colors.grey,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            emergencyDetails?['location']['latitude'],
                            emergencyDetails?['location']['longitude'],
                          ),
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: MarkerId('currentLocation'),
                            position: LatLng(
                                emergencyDetails?['location']['latitude'],
                                emergencyDetails?['location']['longitude']),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueRed),
                          ),
                        },
                      ),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection("users")
                          .doc(emergencyDetails?['user_id'])
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text("${snapshot.error}"),
                          );
                        }

                        final userDetails = snapshot.data!.data();

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              flex: 2,
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(80),
                                      color: majorText,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(80),
                                      child: Image.network(
                                        userDetails?['profile_path'],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 8,
                                  ),
                                  Flexible(
                                    flex: 3,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${userDetails?['first_name']} ${userDetails?['last_name']}",
                                          style: CustomTextStyle.regular,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          "${userDetails?['contact_no']}",
                                          style: CustomTextStyle.regular_minor,
                                        ),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: padding4,
                                              decoration: BoxDecoration(
                                                color:
                                                    (userDetails?['verified'])
                                                        ? Color.fromARGB(
                                                            255, 224, 255, 225)
                                                        : Color.fromARGB(
                                                            255, 255, 224, 224),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                "${(userDetails?['verified']) ? 'Verified' : 'Not Verified'}",
                                                style: TextStyle(
                                                  color:
                                                      (userDetails?['verified'])
                                                          ? Color.fromARGB(
                                                              255, 35, 255, 42)
                                                          : Color.fromARGB(
                                                              255, 184, 0, 0),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 8,
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                if (userDetails?[
                                                        'verification_photo'] ==
                                                    null) {
                                                  Utilities.showSnackBar(
                                                      "This user does not have an ID attached!",
                                                      Colors.red);
                                                  return;
                                                }
                                                showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return AlertDialog(
                                                      content: Padding(
                                                        padding: padding16,
                                                        child: SizedBox(
                                                          width: 200,
                                                          height: 300,
                                                          child: Image.network(
                                                              userDetails?[
                                                                  'verification_photo']),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              child: Text("View ID"),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              flex: 1,
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () async {
                                      print("working");
                                      await FlutterPhoneDirectCaller.callNumber(
                                          "${userDetails?['contact_no']}");
                                    },
                                    icon: Icon(
                                      Icons.call,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      context.go(
                                          '/tanod_home/emergency-details/${widget.id}/emergency-chatroom/${widget.id}');
                                    },
                                    icon: Icon(
                                      Icons.message,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    InputButton(
                      label: "Respond",
                      function: () async {
                        await FirebaseFirestore.instance
                            .collection('sos')
                            .doc(widget.id)
                            .update({
                          'status': 'Handling',
                          'responders': FieldValue.arrayUnion(
                              [FirebaseAuth.instance.currentUser!.uid]),
                        });

                        await FirebaseFirestore.instance
                            .collection('sos')
                            .doc(widget.id)
                            .collection('responders')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .set({
                          'status': 'Responding',
                          'response_start': FieldValue.serverTimestamp(),
                        });
                        context.go(
                            '/tanod_home/emergency-details/${widget.id}/respond/${widget.id}/${emergencyDetails?['location']['latitude']}/${emergencyDetails?['location']['longitude']}');
                      },
                      large: true,
                    ),
                  ],
                );
              }),
        ),
      ),
    );
  }
}
