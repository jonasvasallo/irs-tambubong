import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/widgets/incident_container.dart';
import 'package:irs_app/widgets/past_incident_container.dart';

class UserIncidentsPage extends StatefulWidget {
  const UserIncidentsPage({Key? key}) : super(key: key);

  @override
  _UserIncidentsPageState createState() => _UserIncidentsPageState();
}

class _UserIncidentsPageState extends State<UserIncidentsPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Past Incidents"),
          bottom: const TabBar(
            tabs: [
              Text(
                "Reported Incidents",
                style: TextStyle(
                  fontSize: 16,
                  color: majorText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                "Emergencies",
                style: TextStyle(
                  fontSize: 16,
                  color: majorText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('incidents')
                      .where(
                        "reported_by",
                        isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                      )
                      .snapshots(),
                  builder: (context, snapshot) {
                    List<Widget> incidentsList = [];

                    if (!snapshot.hasData) {
                      return Center(
                        child: Text("No incidents yet."),
                      );
                    }

                    if (snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text("No incidents yet."),
                      );
                    }

                    final incidents = snapshot.data?.docs.toList();
                    for (var incident in incidents!) {
                      String myDate = "test";

                      if (incident['timestamp'] != null) {
                        Timestamp t = incident['timestamp'] as Timestamp;
                        DateTime date = t.toDate();
                        myDate = DateFormat('MMMM dd, y').format(date);
                      }
                      ;
                      final incidentWidget = PastIncidentContainer(
                        id: incident.id,
                        date: myDate,
                        title: incident['title'],
                        location: incident['location_address'],
                        type: 'incident',
                      );
                      incidentsList.add(incidentWidget);
                    }
                    return Column(
                      children: incidentsList,
                    );
                  },
                ),
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('sos')
                      .where(
                        "user_id",
                        isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                      )
                      .snapshots(),
                  builder: (context, snapshot) {
                    List<Widget> incidentsList = [];
                    if (!snapshot.hasData) {
                      return Center(
                        child: Text("No emergencies yet."),
                      );
                    }
                    if (snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text("No emergencies yet."),
                      );
                    }
                    final emergencies = snapshot.data?.docs.toList();
                    for (var emergency in emergencies!) {
                      String myDate = "test";

                      if (emergency['timestamp'] != null) {
                        Timestamp t = emergency['timestamp'] as Timestamp;
                        DateTime date = t.toDate();
                        myDate = DateFormat('MMMM dd, y').format(date);
                      }
                      ;
                      final incidentWidget = PastIncidentContainer(
                        id: emergency.id,
                        date: myDate,
                        title: "SOS CALL",
                        location: "STATUS: ${emergency['status']}",
                        type: 'emergency',
                      );
                      incidentsList.add(incidentWidget);
                    }
                    return Column(
                      children: incidentsList,
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
