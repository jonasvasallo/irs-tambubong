import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/widgets/input_button.dart';

class IncidentDetailsPage extends StatefulWidget {
  final String id;
  const IncidentDetailsPage({Key? key, required this.id}) : super(key: key);

  @override
  _IncidentDetailsPageState createState() => _IncidentDetailsPageState();
}

class _IncidentDetailsPageState extends State<IncidentDetailsPage> {
  late Stream<bool> _userWitnessedStream;
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

  Stream<bool> getUserWitnessedStream(String userId, String incidentId) {
    return FirebaseFirestore.instance
        .collection('incidents')
        .doc(widget.id)
        .collection('witnesses')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  int calculateAge(String birthdateString) {
    DateTime birthdate = DateTime.parse(birthdateString.replaceAll('/', '-'));

    DateTime currentDate = DateTime.now();

    int age = currentDate.year - birthdate.year;

    if (currentDate.month < birthdate.month ||
        (currentDate.month == birthdate.month &&
            currentDate.day < birthdate.day)) {
      age--;
    }

    return age;
  }

  void deleteIncident() async {
    try {
      FirebaseFirestore.instance
          .collection('incidents')
          .doc(widget.id)
          .delete();
      Utilities.showSnackBar("Successfully deleted incident", Colors.green);
      Navigator.of(context).pop();
    } catch (ex) {
      Utilities.showSnackBar("${ex}", Colors.red);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _userWitnessedStream = getUserWitnessedStream(
        FirebaseAuth.instance.currentUser!.uid, widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Incident Details"),
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(Icons.chevron_left),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            FutureBuilder(
              future: getIncidentDetails(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  Map<String, dynamic> incidentDetails = snapshot.data!;

                  String myDate = "test";

                  if (incidentDetails['timestamp'] != null) {
                    Timestamp t = incidentDetails['timestamp'] as Timestamp;
                    DateTime date = t.toDate();
                    myDate =
                        DateFormat('EEEE, MMMM dd, y hh:mm a').format(date);
                  }

                  List<Widget> media_attachments = [];

                  for (var media in incidentDetails['media_attachments']) {
                    final mediaWidget = Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: 300,
                        height: 150,
                        color: Colors.grey,
                        child: Image.network(
                          media,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                    media_attachments.add(mediaWidget);
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(myDate),
                            Text(
                              incidentDetails['title'],
                              style: CustomTextStyle.heading,
                            ),
                            Text(
                              incidentDetails['location_address'],
                              style: CustomTextStyle.regular_minor,
                            ),
                            SizedBox(
                              height: 16,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(48),
                                      color: majorText),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(48),
                                    child: Image.network(
                                      "https://i.stack.imgur.com/l60Hf.png",
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 8,
                                ),
                                (incidentDetails['user_details']['user_type'] ==
                                        'resident')
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(incidentDetails['user_details']
                                              ['gender']),
                                          Text(
                                              "${calculateAge(incidentDetails['user_details']['birthday'])} years old"),
                                        ],
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(incidentDetails['user_details']
                                              ['first_name']),
                                          Text(
                                              "${incidentDetails['user_details']['user_type'].toString().toUpperCase()}"),
                                        ],
                                      ),
                              ],
                            ),
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
                              width: MediaQuery.of(context).size.width - 32,
                              height: 150,
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: accentColor, width: 2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: StreamBuilder(
                                stream: FirebaseFirestore.instance
                                    .collection('incidents')
                                    .doc(widget.id)
                                    .collection('live_status')
                                    .orderBy('timestamp', descending: true)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty) {
                                    return Center(
                                      child: Text("No status yet..."),
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Text("${snapshot.error}"),
                                    );
                                  }

                                  List<Widget> statusWidgets = [];

                                  final statuses = snapshot.data!.docs;

                                  for (var status in statuses) {
                                    String myDate = "Error fetching date";
                                    if (status['timestamp'] != null) {
                                      Timestamp t =
                                          status['timestamp'] as Timestamp;
                                      DateTime date = t.toDate();
                                      myDate = DateFormat('MM/dd hh:mm a')
                                          .format(date);
                                    }

                                    statusWidgets.add(
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            myDate,
                                          ),
                                          SizedBox(
                                            width: 16,
                                          ),
                                          Flexible(
                                            child: Text(
                                              status['status_content'],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    statusWidgets.add(
                                      SizedBox(
                                        height: 16,
                                      ),
                                    );
                                  }

                                  return SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: statusWidgets,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(
                              height: 16,
                            ),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: media_attachments,
                              ),
                            ),
                            (incidentDetails['reported_by'] !=
                                    FirebaseAuth.instance.currentUser?.uid)
                                ? StreamBuilder<bool>(
                                    stream: getUserWitnessedStream(
                                        FirebaseAuth.instance.currentUser!.uid,
                                        widget.id),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.active) {
                                        bool userWitnessed =
                                            snapshot.data ?? false;

                                        return (userWitnessed)
                                            ? Center(
                                                child: Text(
                                                  "You have provided your information to this incident. Thanks for your support.",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: accentColor,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              )
                                            : InputButton(
                                                label: "I WITNESSED THIS",
                                                function: () {
                                                  context.go(
                                                      "/home/incident/${widget.id}/witness/${widget.id}");
                                                },
                                                large: true);
                                      } else {
                                        return CircularProgressIndicator();
                                      }
                                    },
                                  )
                                : InputButton(
                                    label: "OPEN CHATROOM",
                                    function: () {
                                      context.go(
                                        '/home/incident/${widget.id}/chatroom/${widget.id}',
                                      );
                                    },
                                    large: true,
                                  ),
                            (incidentDetails['reported_by'] ==
                                        FirebaseAuth
                                            .instance.currentUser?.uid &&
                                    incidentDetails['status'] == "Verifying")
                                ? Align(
                                    alignment: Alignment.center,
                                    child: TextButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text("Delete Incident"),
                                                content: Text(
                                                    "Are you sure you want to delete this incident? This action cannot be reversed."),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: Text("Cancel"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      print("delete incident");
                                                      deleteIncident();
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: Text("Yes"),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        child: Text(
                                          "Delete Incident",
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        )),
                                  )
                                : SizedBox(),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
