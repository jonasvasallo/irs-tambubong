import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_capstone/core/utilities.dart';
import 'package:irs_capstone/models/incident_model.dart';
import 'package:irs_capstone/widgets/incident_history_item.dart';

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
                      .where('status',
                          whereIn: ['Resolved', 'Closed']).snapshots(),
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
                                    '/tanod_home/response-history/details/${doc.id}');
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
                child: Column(
                  children: [],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
