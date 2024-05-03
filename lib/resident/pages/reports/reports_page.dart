import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:irs_capstone/constants.dart';
import 'package:irs_capstone/widgets/incident_container.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
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
                    .snapshots(),
                builder: (context, snapshot) {
                  List<Widget> incidentsList = [];
                  if (!snapshot.hasData) {
                    return Text("No Data");
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
