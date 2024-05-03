import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:irs_capstone/widgets/incident_container.dart';

class UserIncidentsPage extends StatefulWidget {
  const UserIncidentsPage({Key? key}) : super(key: key);

  @override
  _UserIncidentsPageState createState() => _UserIncidentsPageState();
}

class _UserIncidentsPageState extends State<UserIncidentsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Incidents"),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(
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
                    return Center(child: Text("No incidents reported"));
                  }
                  final incidents = snapshot.data?.docs.toList();
                  for (var incident in incidents!) {
                    String myDate = "test";

                    if (incident['timestamp'] != null) {
                      Timestamp t = incident['timestamp'] as Timestamp;
                      DateTime date = t.toDate();
                      myDate = DateFormat('MM/dd hh:mm').format(date);
                    }
                    final incidentWidget = IncidentContainer(
                      id: incident.id,
                      title: incident['title'],
                      details: incident['details'],
                      date: myDate,
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
        ));
  }
}
