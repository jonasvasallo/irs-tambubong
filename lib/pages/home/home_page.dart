import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:irs_capstone/constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(14.9690824, 120.9244701);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

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

class IncidentContainer extends StatelessWidget {
  final String id;
  final String title;
  final String details;
  final String date;
  const IncidentContainer(
      {Key? key,
      required this.title,
      required this.details,
      required this.date,
      required this.id})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.go('/home/incident/${id}');
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 248, 246, 246),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: minorText, width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      flex: 3,
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: CustomTextStyle.subheading,
                      ),
                    ),
                    Text(
                      date,
                      overflow: TextOverflow.ellipsis,
                      style: CustomTextStyle.regular,
                    ),
                  ],
                ),
                Text(
                  details,
                  overflow: TextOverflow.ellipsis,
                  style: CustomTextStyle.regular_minor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
