import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:irs_capstone/constants.dart';
import 'package:irs_capstone/core/utilities.dart';

class TanodResponseDetailsPage extends StatefulWidget {
  final String id;
  const TanodResponseDetailsPage({Key? key, required this.id})
      : super(key: key);

  @override
  _TanodResponseDetailsPageState createState() =>
      _TanodResponseDetailsPageState();
}

class _TanodResponseDetailsPageState extends State<TanodResponseDetailsPage> {
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
            future: FirebaseFirestore.instance
                .collection('incidents')
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

              final incidentDetails = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    incidentDetails['title'],
                    style: CustomTextStyle.subheading,
                  ),
                  Text(
                    Utilities.convertDate(incidentDetails['timestamp']),
                    style: CustomTextStyle.regular_minor,
                  ),
                  Text(
                    incidentDetails['location_address'],
                    style: CustomTextStyle.regular,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FutureBuilder(
                          future: FirebaseFirestore.instance
                              .collection('incident_tags')
                              .doc(incidentDetails['incident_tag'])
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Text("${snapshot.error}"),
                              );
                            }

                            final incidentTagDetails = snapshot.data!;

                            return Text(
                              incidentTagDetails['tag_name'],
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          }),
                      Text(
                        incidentDetails['status'],
                        style: CustomTextStyle.regular_minor,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(incidentDetails['reported_by'])
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text("${snapshot.error}"),
                          );
                        }

                        final userDetails = snapshot.data!;
                        return Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(48),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(48),
                                child:
                                    Image.network(userDetails['profile_path']),
                              ),
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${userDetails['first_name']} ${userDetails['middle_name']} ${userDetails['last_name']}",
                                  style: CustomTextStyle.regular,
                                ),
                                Text(
                                  userDetails['contact_no'],
                                  style: CustomTextStyle.regular_minor,
                                ),
                              ],
                            ),
                          ],
                        );
                      }),
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
                  Divider(),
                  SizedBox(
                    height: 16,
                  ),
                  FutureBuilder(
                    future: FirebaseFirestore.instance
                        .collection('incidents')
                        .doc(widget.id)
                        .collection('responders')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
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

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Center(
                          child: Text("Document does not exist yet."),
                        );
                      }

                      final responderDetails = snapshot.data!;

                      return Column(
                        children: [
                          Text(
                            "Response Status: ${responderDetails['status']}",
                            style: CustomTextStyle.subheading,
                          ),
                          Text(
                              "Response Start: ${Utilities.convertDate(responderDetails['response_start'])}"),
                          Text(
                              "Response End: ${Utilities.convertDate(responderDetails['response_end'])}"),
                          SizedBox(
                            height: 16,
                          ),
                          Text(
                            "Response Attachment",
                            style: CustomTextStyle.subheading,
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width - 32,
                            height: 250,
                            color: Colors.grey,
                            child: Image.network(
                              responderDetails['response_photo'],
                              fit: BoxFit.cover,
                            ),
                          )
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
