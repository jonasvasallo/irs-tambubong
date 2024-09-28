import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/models/incident_model.dart';
import 'package:irs_app/widgets/input_button.dart';

class TanodIncidentDetailsPage extends StatefulWidget {
  final String id;
  const TanodIncidentDetailsPage({Key? key, required this.id})
      : super(key: key);

  @override
  _TanodIncidentDetailsPageState createState() =>
      _TanodIncidentDetailsPageState();
}

class _TanodIncidentDetailsPageState extends State<TanodIncidentDetailsPage> {
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
        title: Text("Incident Details"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: FutureBuilder(
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

                Incident incident = new Incident(incident_id: widget.id);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            incidentDetails['title'],
                            style: CustomTextStyle.heading,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.go(
                                '/tanod_home/incident-details/${widget.id}/incident-chatroom/${widget.id}');
                          },
                          child: Icon(
                            Icons.message,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      Utilities.convertDate(incidentDetails['timestamp']),
                      style: CustomTextStyle.regular_minor,
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Text(
                      incidentDetails['details'],
                      style: CustomTextStyle.regular,
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
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: minorText,
                        ),
                        SizedBox(
                          width: 16,
                        ),
                        Flexible(
                          child: Text(
                            incidentDetails['location_address'],
                            style: CustomTextStyle.regular,
                          ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          flex: 4,
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(80),
                                  color: majorText,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(80),
                                  child: Image.network(
                                    incidentDetails['user_details']
                                        ['profile_path'],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 16,
                              ),
                              Flexible(
                                flex: 3,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${incidentDetails['user_details']['first_name']} ${incidentDetails['user_details']['last_name']}",
                                      style: CustomTextStyle.regular,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      "${incidentDetails['user_details']['contact_no']}",
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
                                                (incidentDetails['user_details']
                                                        ['verified'])
                                                    ? Color.fromARGB(
                                                        255, 224, 255, 225)
                                                    : Color.fromARGB(
                                                        255, 255, 224, 224),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "${(incidentDetails['user_details']['verified']) ? 'Verified' : 'Not Verified'}",
                                            style: TextStyle(
                                              color: (incidentDetails[
                                                          'user_details']
                                                      ['verified'])
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
                                            if (incidentDetails['user_details']
                                                    ['verification_photo'] ==
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
                                                          incidentDetails[
                                                                  'user_details']
                                                              [
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
                              TextButton(
                                onPressed: () async {
                                  print("working");
                                  await FlutterPhoneDirectCaller.callNumber(
                                      "${incidentDetails['user_details']['contact_no']}");
                                },
                                child: Icon(
                                  Icons.call,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    InputButton(
                      label: "Respond",
                      function: () async {
                        incident.update({
                          'status': 'Handling',
                          'responders': FieldValue.arrayUnion(
                              [FirebaseAuth.instance.currentUser!.uid]),
                        });

                        await FirebaseFirestore.instance
                            .collection('incidents')
                            .doc(widget.id)
                            .collection('responders')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .set({
                          'status': 'Responding',
                          'response_start': FieldValue.serverTimestamp(),
                        });
                        context.go(
                            '/tanod_home/incident-details/${widget.id}/respond/${widget.id}/${incidentDetails['coordinates']['latitude']}/${incidentDetails['coordinates']['longitude']}');
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
