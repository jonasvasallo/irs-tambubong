import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:irs_app/constants.dart';

class ComplaintDetailsPage extends StatefulWidget {
  final String id;
  const ComplaintDetailsPage({Key? key, required this.id}) : super(key: key);

  @override
  _ComplaintDetailsPageState createState() => _ComplaintDetailsPageState();
}

class _ComplaintDetailsPageState extends State<ComplaintDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Complaint Details"),
      ),
      body: SingleChildScrollView(
        padding: padding16,
        child: FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('complaints')
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

              final caseDetails = snapshot.data!.data() as Map<String, dynamic>;
              String myDate = "test";

              if (caseDetails['issued_at'] != null) {
                Timestamp t = caseDetails['issued_at'] as Timestamp;
                DateTime date = t.toDate();
                myDate = DateFormat('EEE, MMMM dd, y, hh:mm aa').format(date);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Complaint No. ${widget.id}",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    myDate,
                  ),
                  Text(
                    "Status: ${caseDetails['status']}",
                  ),
                  Text(
                    "Complaint: ${caseDetails['description']}",
                  ),
                  Divider(),
                  Text(
                    "Respondent",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    "Name: ${caseDetails['respondent_info'][0] ?? 'N/A'}",
                  ),
                  Text(
                      "Contact Number: ${caseDetails['respondent_info'][1] ?? 'N/A'}"),
                  Text(
                      "Address: ${caseDetails['respondent_info'][2] ?? 'N/A'}"),
                  Text(
                      "Description: ${caseDetails['respondent_description'] ?? 'N/A'}"),
                  Divider(),
                  Text(
                    "Scheduled Hearings",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  (caseDetails['hearings'] != null &&
                          caseDetails['hearings'].isNotEmpty)
                      ? Column(
                          children: [
                            for (var hearing in caseDetails['hearings'])
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    FutureBuilder(
                                        future: FirebaseFirestore.instance
                                            .collection('schedules')
                                            .doc(hearing['schedule_id'])
                                            .get(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          }
                                          if (snapshot.hasError) {
                                            return Center(
                                              child: Text("${snapshot.error}"),
                                            );
                                          }

                                          final scheduleDetails = snapshot.data!
                                              .data() as Map<String, dynamic>;
                                          String scheduleDate = "test";

                                          if (scheduleDetails[
                                                  'meeting_start'] !=
                                              null) {
                                            Timestamp t =
                                                caseDetails['issued_at']
                                                    as Timestamp;
                                            DateTime date = t.toDate();
                                            scheduleDate = DateFormat(
                                                    'MMMM dd, y, hh:mm aa')
                                                .format(date);
                                          }

                                          return Expanded(
                                            child: Text(
                                              "${scheduleDetails['title'] ?? 'N/A'} - ${scheduleDate}",
                                            ),
                                          );
                                        }),
                                    Expanded(
                                      child: Text(
                                        "Status: ${hearing['status'] ?? 'N/A'}",
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        )
                      : Text("No hearings scheduled yet."),
                ],
              );
            }),
      ),
    );
  }
}
