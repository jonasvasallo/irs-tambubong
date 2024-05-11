import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:irs_capstone/constants.dart';
import 'package:irs_capstone/core/utilities.dart';
import 'package:irs_capstone/models/responder_rating_data.dart';
import 'package:irs_capstone/models/user_model.dart';
import 'package:irs_capstone/widgets/input_button.dart';
import 'package:irs_capstone/widgets/input_field.dart';
import 'package:irs_capstone/widgets/rating_container.dart';

class UserIncidentReviewPage extends StatefulWidget {
  final String id;
  const UserIncidentReviewPage({Key? key, required this.id}) : super(key: key);

  @override
  _UserIncidentReviewPageState createState() => _UserIncidentReviewPageState();
}

class _UserIncidentReviewPageState extends State<UserIncidentReviewPage> {
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
            .collection('incidents')
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
          'incident_id': widget.id,
          'type': 'incident',
        });
      } catch (err) {
        Utilities.showSnackBar("${err}", Colors.red);
      }
    }
    Navigator.of(dialogContext).pop();
    Utilities.showSnackBar("Thank you for your review!", Colors.green);
    Navigator.of(context).pop();
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
                  .collection('incidents')
                  .doc(widget.id)
                  .collection('responders')
                  .where('status', isEqualTo: 'Responded')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: Text("No incidents yet."),
                  );
                }
                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text("No responders yet."),
                  );
                }
                final incidentDetails = snapshot.data!.docs.toList();
                List<Widget> ratingContainers = [];
                for (var responder in incidentDetails) {
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
                          userType: residentDetails['user_type'],
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
