import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/models/responder_rating_data.dart';
import 'package:irs_app/models/user_model.dart';
import 'package:irs_app/widgets/input_button.dart';
import 'package:irs_app/widgets/input_field.dart';
import 'package:irs_app/widgets/rating_container.dart';

class UserEmergencyReviewPage extends StatefulWidget {
  final String id;
  const UserEmergencyReviewPage({Key? key, required this.id}) : super(key: key);

  @override
  _UserEmergencyReviewPageState createState() =>
      _UserEmergencyReviewPageState();
}

class _UserEmergencyReviewPageState extends State<UserEmergencyReviewPage> {
  List<ResponderRatingData> responderRatingDataList = [];
  void updateResponderRatingData(
      String responderId, double rating, String message) {
    ResponderRatingData newData =
        ResponderRatingData(id: responderId, rating: rating, message: message);
    int index =
        responderRatingDataList.indexWhere((data) => data.id == responderId);
    if (index != -1) {
      // If rating data for this responder already exists, update it
      responderRatingDataList[index] = newData;
    } else {
      // If rating data for this responder doesn't exist, add it
      responderRatingDataList.add(newData);
    }
  }

  void submitRatingData() async {
    BuildContext dialogContext = context;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        dialogContext = context;
        return Center(
          child: CircularProgressIndicator(
            color: accentColor,
          ),
        );
      },
    );
    for (var data in responderRatingDataList) {
      // Send rating data to the database for each responder
      print(data.id);
      print(data.rating);
      print(data.message);
      try {
        await FirebaseFirestore.instance
            .collection('sos')
            .doc(widget.id)
            .update({
          'rated': true,
          'status': 'Closed',
        });
        await FirebaseFirestore.instance
            .collection('users')
            .doc(data.id)
            .collection('ratings')
            .doc(widget.id)
            .set({
          'rating': data.rating,
          'message': data.message,
          'emergency_id': widget.id,
          'type': 'emergency',
          'timestamp': FieldValue.serverTimestamp(),
          'reviewer_id': FirebaseAuth.instance.currentUser!.uid,
        });
        await FirebaseFirestore.instance.collection('ratings').add({
          'tanod_id': data.id,
          'emergency_id': widget.id,
          'rating': data.rating,
          'message': data.message,
          'type': 'emergency',
          'timestamp': FieldValue.serverTimestamp(),
          'reviewer_id': FirebaseAuth.instance.currentUser!.uid,
        });
      } catch (err) {
        Utilities.showSnackBar("${err}", Colors.red);
      }
    }
    Navigator.of(dialogContext).pop();
    Utilities.showSnackBar("Thank you for your review!", Colors.green);
    Navigator.of(context).pop();
  }

  Duration calculateResponseTime(Timestamp start, Timestamp end) {
    return end.toDate().difference(start.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Review"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: padding16,
          child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('sos')
                  .doc(widget.id)
                  .collection('responders')
                  .where('status', isEqualTo: 'Responded')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: Text(
                        "No responders. If you think this is a problem, please submit a support ticket."),
                  );
                }
                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                        "No responders. If you think this is a problem, please submit a support ticket."),
                  );
                }
                final incidentDetails = snapshot.data!.docs.toList();
                List<Widget> ratingContainers = [];
                for (var responder in incidentDetails) {
                  final responseStart =
                      responder['response_start'] as Timestamp;
                  final responseEnd = responder['response_end'] as Timestamp;
                  final responseTime =
                      calculateResponseTime(responseStart, responseEnd);
                  final rating = FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(responder.id)
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
                        final residentDetails = snapshot.data!;
                        return RatingContainer(
                          id: responder.id,
                          name:
                              "${residentDetails['first_name']} ${residentDetails['last_name']}",
                          responseTime: "${responseTime.inMinutes} minutes",
                          profileURL: residentDetails['profile_path'],
                          onUpdateRatingData: updateResponderRatingData,
                        );
                      });
                  ResponderRatingData newData = ResponderRatingData(
                    id: responder.id,
                    rating: 5,
                    message: '',
                  );
                  responderRatingDataList.add(newData);
                  ratingContainers.add(rating);
                }
                return Column(
                  children: [
                    Column(
                      children: ratingContainers,
                    ),
                    InputButton(
                      label: "SUBMIT",
                      function: () {
                        submitRatingData();
                      },
                      large: true,
                    ),
                  ],
                );
              }),
        ),
      ),
    );
  }
}
