import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/models/incident_model.dart';
import 'package:irs_app/widgets/incident_history_item.dart';

class TanodResponseHistoryPage extends StatefulWidget {
  const TanodResponseHistoryPage({Key? key}) : super(key: key);

  @override
  _TanodResponseHistoryPageState createState() =>
      _TanodResponseHistoryPageState();
}

class _TanodResponseHistoryPageState extends State<TanodResponseHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(tabs: [Text("Incidents"), Text("Emergencies")]),
          title: Text("Response History"),
        ),
        body: TabBarView(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('incidents')
                      .where('responders',
                          arrayContains: FirebaseAuth.instance.currentUser!.uid)
                      .where('status', whereIn: ['Resolved', 'Closed'])
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (snapshot.hasError) {
                      print(snapshot.error);
                      return Center(
                        child: Text("${snapshot.error}"),
                      );
                    }
                    if (snapshot.data!.size == 0) {
                      return Center(
                        child: Text("No responses yet."),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    return Column(
                      children: docs.map((doc) {
                        return FutureBuilder(
                          future: Incident(incident_id: doc.id)
                              .getTag(doc['incident_tag']),
                          builder: (context, tagSnapshot) {
                            if (tagSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator(); // or any loading widget
                            }
                            if (tagSnapshot.hasError) {
                              return Text("Error: ${tagSnapshot.error}");
                            }
                            String tag_name = tagSnapshot.data as String;
                            return GestureDetector(
                              onTap: () {
                                context.go(
                                    '/tanod_home/response-history/details/${doc.id}/incident');
                              },
                              child: IncidentHistoryItem(
                                title: doc['title'],
                                tag: tag_name,
                                status: doc['status'],
                                date: Utilities.convertDate(doc['timestamp']),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('sos')
                      .where('responders',
                          arrayContains: FirebaseAuth.instance.currentUser!.uid)
                      .where('status', whereIn: ['Resolved', 'Closed'])
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (snapshot.hasError) {
                      print(snapshot.error);
                      return Center(
                        child: Text("${snapshot.error}"),
                      );
                    }
                    if (snapshot.data!.size == 0) {
                      return Center(
                        child: Text("No responses yet."),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    return Column(
                      children: docs.map((doc) {
                        return FutureBuilder(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(doc['user_id'])
                              .get(),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator(); // or any loading widget
                            }
                            if (userSnapshot.hasError) {
                              return Text("Error: ${userSnapshot.error}");
                            }
                            final userDetails = userSnapshot.data!.data()
                                as Map<String, dynamic>;
                            return GestureDetector(
                              onTap: () {
                                context.go(
                                    '/tanod_home/response-history/details/${doc.id}/emergency');
                              },
                              child: IncidentHistoryItem(
                                title: "SOS CALL",
                                tag:
                                    "${userDetails['first_name']} ${userDetails['last_name']}",
                                status: doc['status'],
                                date: Utilities.convertDate(doc['timestamp']),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
