import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/widgets/input_button.dart';

class UserIncidentHistoryPage extends StatefulWidget {
  final String id;
  const UserIncidentHistoryPage({Key? key, required this.id}) : super(key: key);

  @override
  _UserIncidentHistoryPageState createState() =>
      _UserIncidentHistoryPageState();
}

class _UserIncidentHistoryPageState extends State<UserIncidentHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Incident Details",
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('incidents')
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

              final incidentDetails = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    incidentDetails['title'],
                    style: CustomTextStyle.subheading,
                  ),
                  Text(
                    Utilities.convertDate(incidentDetails['timestamp']),
                    style: CustomTextStyle.regular_minor,
                  ),
                  Text(
                    incidentDetails['location_address'],
                    style: CustomTextStyle.regular,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FutureBuilder(
                          future: FirebaseFirestore.instance
                              .collection('incident_tags')
                              .doc(incidentDetails['incident_tag'])
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

                            final incidentTagDetails = snapshot.data!;

                            return Text(
                              incidentTagDetails['tag_name'],
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          }),
                      Text(
                        incidentDetails['status'],
                        style: CustomTextStyle.regular_minor,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(incidentDetails['reported_by'])
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

                        final userDetails = snapshot.data!;
                        return Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(48),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(48),
                                child: Image.network(
                                  userDetails['profile_path'],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${userDetails['first_name']} ${userDetails['middle_name']} ${userDetails['last_name']}",
                                  style: CustomTextStyle.regular,
                                ),
                                Text(
                                  userDetails['contact_no'],
                                  style: CustomTextStyle.regular_minor,
                                ),
                              ],
                            ),
                          ],
                        );
                      }),
                  SizedBox(
                    height: 16,
                  ),
                  Text(
                    incidentDetails['details'],
                    style: CustomTextStyle.regular,
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  Container(
                    width: double.infinity,
                    height: 200,
                    color: majorText,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                            incidentDetails['coordinates']['latitude'],
                            incidentDetails['coordinates']['longitude']),
                        zoom: 18,
                      ),
                      circles: Set.from([
                        Circle(
                          circleId: CircleId("customCircle"),
                          center: LatLng(
                              incidentDetails['coordinates']['latitude'],
                              incidentDetails['coordinates']['longitude']),
                          radius: 5,
                          fillColor: Color.fromARGB(98, 255, 0, 0),
                          strokeColor: Color.fromARGB(255, 255, 0, 0),
                        ),
                      ]),
                    ),
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  (incidentDetails['status'] == 'Resolved' &&
                          (incidentDetails['rated'] == false))
                      ? InputButton(
                          label: "Leave a review",
                          function: () {
                            context.go(
                                '/profile/incidents/${widget.id}/review/${widget.id}');
                          },
                          large: true,
                        )
                      : SizedBox(),
                  (incidentDetails['rated'] == true)
                      ? Align(
                          alignment: Alignment.center,
                          child: Text(
                            "Thanks for leaving a review!",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : SizedBox(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
