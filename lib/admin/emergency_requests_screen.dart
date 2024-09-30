import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EmergencyRequestsScreen extends StatefulWidget {
  const EmergencyRequestsScreen({Key? key}) : super(key: key);

  @override
  _EmergencyRequestsScreenState createState() =>
      _EmergencyRequestsScreenState();
}

class _EmergencyRequestsScreenState extends State<EmergencyRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Emergencies"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('sos')
              .where('status', whereIn: ['Active', 'Handling']).snapshots(),
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

            if (!snapshot.hasData) {
              return Center(
                child: Text("Waiting for new requests..."),
              );
            }
            List<Widget> requestsWidgets = [];

            final requests = snapshot.data!.docs.toList();

            for (var request in requests) {
              requestsWidgets.add(
                ListTile(
                  title: Text("${request['status']}"),
                ),
              );
            }

            return Column(
              children: requestsWidgets,
            );
          },
        ),
      ),
    );
  }
}
