import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:irs_app/core/utilities.dart';

class ResponderRemoveContainer extends StatefulWidget {
  final String id;
  final String uid;
  const ResponderRemoveContainer({
    Key? key,
    required this.id,
    required this.uid,
  }) : super(key: key);

  @override
  _ResponderRemoveContainerState createState() =>
      _ResponderRemoveContainerState();
}

class _ResponderRemoveContainerState extends State<ResponderRemoveContainer> {
  Future<void> handleRemovePerson(String personId, String incidentId) async {
    try {
      // Reference to the incident document
      DocumentReference incidentDocRef =
          FirebaseFirestore.instance.collection('sos').doc(incidentId);
      DocumentSnapshot incidentDoc = await incidentDocRef.get();

      if (incidentDoc.exists) {
        Map<String, dynamic> incidentData =
            incidentDoc.data() as Map<String, dynamic>;
        List<dynamic> responders = incidentData['responders'] ?? [];
        String status = incidentData['status'];

        if (status != "Active" && status != "Handling") {
          Utilities.showSnackBar(
              "Cannot remove responder unless status is Active or Handling!",
              Colors.red);
          return;
        }

        // Check if the person is in the responders list
        if (!responders.contains(personId)) {
          Utilities.showSnackBar(
              "User is not in the responders list.", Colors.red);
          return;
        } else {
          // Remove the person from the responders list
          await incidentDocRef.update({
            'responders': FieldValue.arrayRemove([personId])
          });

          // Add an entry to the audit collection
          await FirebaseFirestore.instance.collection('audits').add({
            'uid': FirebaseAuth.instance.currentUser!.uid,
            'action': 'delete',
            'module': 'sos',
            'description':
                'Removed user $personId as a responder for incident ID $incidentId',
            'timestamp': FieldValue.serverTimestamp(),
          });

          Utilities.showSnackBar(
              "Successfully removed responder", Colors.green);
        }
      } else {
        Utilities.showSnackBar("Document not found.", Colors.red);
      }
    } catch (error) {
      print("Error removing person from responders: $error");
      Utilities.showSnackBar(
          "Error removing person from responders", Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
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

          if (!snapshot.hasData) {
            return Center(
              child: Text("No data available."),
            );
          }
          var document = snapshot.data!;
          var data = document.data() as Map<String, dynamic>?;
          if (data == null) {
            return Center(
              child: Text("Document has no data."),
            );
          }
          return Container(
            width: MediaQuery.of(context).size.width - 32,
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(
                          50,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          50,
                        ),
                        child: Image.network(
                          data['profile_path'],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("${data['first_name']} ${data['last_name']}"),
                        Text("${data['contact_no']}"),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => handleRemovePerson(widget.uid, widget.id),
                  icon: Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          );
        });
  }
}
