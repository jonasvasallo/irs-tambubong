import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:irs_app/core/utilities.dart';

class AddResponderDialog extends StatefulWidget {
  final String id;
  final List<dynamic> responders;
  final double latitude;
  final double longitude;
  const AddResponderDialog(
      {Key? key,
      required this.id,
      required this.responders,
      required this.latitude,
      required this.longitude})
      : super(key: key);

  @override
  _AddResponderDialogState createState() => _AddResponderDialogState();
}

class _AddResponderDialogState extends State<AddResponderDialog> {
  Future<List<Map<String, dynamic>>> fetchAvailablePersons() async {
    try {
      DocumentReference incidentDocRef =
          FirebaseFirestore.instance.collection('sos').doc(widget.id);
      DocumentSnapshot incidentDoc = await incidentDocRef.get();

      Map<String, dynamic> incidentData =
          incidentDoc.data() as Map<String, dynamic>;
      List<dynamic> responders = incidentData['responders'] ?? [];

      // Query to get all 'tanod' users who are online and not in responders list
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('user_type', isEqualTo: 'tanod')
          .where('isOnline', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> availablePersons = querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .where((person) => !responders.contains(person['id']))
          .toList();

      return availablePersons;
    } catch (error) {
      print("Error fetching available persons: $error");
      throw error;
    }
  }

  int calculateDistance(double startLatitude, double startLongitude,
      double endLatitude, double endLongitude) {
    // Calculate distance in meters
    double distance = Geolocator.distanceBetween(
        startLatitude, startLongitude, endLatitude, endLongitude);

    // Round up to the nearest whole number
    return distance.ceil();
  }

  void handleAddPerson(personId) async {
    try {
      DocumentReference incidentDocRef =
          FirebaseFirestore.instance.collection('sos').doc(widget.id);
      DocumentSnapshot incidentDoc = await incidentDocRef.get();
      if (!incidentDoc.exists) {
        Utilities.showSnackBar("Document not found!", Colors.red);
        return;
      }
      Map<String, dynamic> incidentData =
          incidentDoc.data() as Map<String, dynamic>;
      List<dynamic> responders = incidentData['responders'] ?? [];
      if (incidentData['status'] != "Active" &&
          incidentData['status'] != "Handling") {
        Utilities.showSnackBar(
            "Cannot add responder unless status is Active or Handling!",
            Colors.red);
        return;
      }

      // Check if the person is already a responder
      if (responders.contains(personId)) {
        Utilities.showSnackBar(
            "User is already in the responders list!", Colors.red);
      } else {
        // await sendNotificationToUser(personId);
        await incidentDocRef.update({
          'responders': FieldValue.arrayUnion([personId])
        });

        await FirebaseFirestore.instance.collection('audits').add({
          'uid': FirebaseAuth.instance.currentUser!.uid,
          'action': 'update',
          'module': 'sos',
          'description':
              'Added user $personId as a responder for emergency ID ${widget.id}',
          'timestamp': FieldValue.serverTimestamp(),
        });
        Utilities.showSnackBar("Successfully added responder", Colors.green);
      }
    } catch (err) {
      Utilities.showSnackBar(
          "An error has occured while trying to add this responder",
          Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add a responder"),
      content: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchAvailablePersons(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Text('No available responders found.');
          }

          // Available persons
          List<Map<String, dynamic>> availablePersons = snapshot.data!;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: availablePersons.map((person) {
              // Extract the person's current location
              var personLocation = person['current_location'];
              int distance = 0;

              if (personLocation != null) {
                distance = calculateDistance(
                  widget.latitude,
                  widget.longitude,
                  personLocation['latitude'],
                  personLocation['longitude'],
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
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Image.network(
                              "${person['profile_path']}",
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                "${person['first_name']} ${person['last_name']}",
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(person['isOnline'] ? 'Online' : 'Offline'),
                            Text("${distance}m away"),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => handleAddPerson(person['id']),
                      icon: Icon(Icons.add, color: Colors.green),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
