import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_app/constants.dart';

class TanodProfilePage extends StatefulWidget {
  const TanodProfilePage({Key? key}) : super(key: key);

  @override
  _TanodProfilePageState createState() => _TanodProfilePageState();
}

class _TanodProfilePageState extends State<TanodProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .snapshots(),
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

                final userDetails = snapshot.data!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(150),
                          color: Colors.grey,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(150),
                          child: Image.network(
                            userDetails['profile_path'],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Text(
                      "${userDetails['first_name']} ${userDetails['middle_name']} ${userDetails['last_name']}",
                      style: CustomTextStyle.heading,
                    ),
                    TextButton(
                        onPressed: () {
                          context.go('/tanod_home/profile/update');
                        },
                        child: Text("Update Profile"),
                        style: ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(
                                Color.fromARGB(255, 240, 250, 255)))),
                    SizedBox(
                      height: 16,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            FutureBuilder(
                              future: checkIncidents(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (snapshot.hasError) {
                                  return Text("${snapshot.error}");
                                }
                                int incidentResponded = snapshot.data ?? 0;
                                return Text(
                                  "${incidentResponded}",
                                  style: CustomTextStyle.subheading,
                                );
                              },
                            ),
                            Text(
                              "Responded",
                              style: CustomTextStyle.regular,
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            FutureBuilder(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .collection('ratings')
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
                                // Handle when data is available
                                if (snapshot.hasData) {
                                  var ratingDocs = snapshot.data!.docs;

                                  if (ratingDocs.isEmpty) {
                                    return Center(
                                        child: Text('No ratings found.'));
                                  }

                                  // Calculate the average rating
                                  double totalRating = 0;
                                  int ratingCount = ratingDocs.length;

                                  ratingDocs.forEach((doc) {
                                    var ratingData =
                                        doc.data() as Map<String, dynamic>;
                                    totalRating += ratingData['rating'];
                                  });

                                  double averageRating =
                                      totalRating / ratingCount;
                                  return Text(
                                    "${averageRating.toStringAsFixed(1)}",
                                    style: CustomTextStyle.subheading,
                                  );
                                }
                                return Text(
                                  "4.5",
                                  style: CustomTextStyle.subheading,
                                );
                              },
                            ),
                            Text(
                              "Avg rating",
                              style: CustomTextStyle.regular,
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Divider(
                      color: minorText,
                      thickness: 1,
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Recent reviews",
                        style: CustomTextStyle.subheading,
                      ),
                    ),
                    SizedBox(
                      height: 24,
                    ),
                    FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .collection('ratings')
                          .orderBy('timestamp', descending: true)
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
                        // Handle when data is available
                        if (snapshot.hasData) {
                          print(FirebaseAuth.instance.currentUser!.uid);
                          var ratingDocs = snapshot.data!.docs;

                          if (ratingDocs.isEmpty) {
                            return Center(child: Text('No ratings found.'));
                          }

                          return Column(
                            children: ratingDocs.map((doc) {
                              var ratingData =
                                  doc.data() as Map<String, dynamic>;
                              // Replace with your own data structure
                              var ratingValue = ratingData['rating'];
                              var comment = ratingData['message'];

                              return ListTile(
                                title: Row(
                                  children: [
                                    Text('Rating: $ratingValue'),
                                    SizedBox(
                                      width: 8,
                                    ),
                                    RatingBar(
                                      ignoreGestures: true,
                                      minRating: 1,
                                      maxRating: 5,
                                      initialRating: ratingValue,
                                      allowHalfRating: false,
                                      itemSize: 28,
                                      glowColor: Colors.lightGreen,
                                      glowRadius: 5,
                                      updateOnDrag: true,
                                      ratingWidget: RatingWidget(
                                        full: Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                        ),
                                        half: Icon(
                                          Icons.star_half,
                                          color: Colors.amber,
                                        ),
                                        empty: Icon(
                                          Icons.star_border,
                                          color: Colors.amber,
                                        ),
                                      ),
                                      onRatingUpdate: (value) {},
                                    ),
                                  ],
                                ),
                                subtitle: Text('Comment: $comment'),
                              );
                            }).toList(),
                          );
                        }

                        // Handle any other state (e.g., no data)
                        return Center(child: Text('No data available.'));
                      },
                    ),
                  ],
                );
              }),
        ),
      ),
    );
  }

  Future<int> checkIncidents() async {
    try {
      // Fetch documents in the 'incidents' collection
      QuerySnapshot incidentQuerySnapshot = await FirebaseFirestore.instance
          .collection('incidents')
          .where('responders',
              arrayContains: FirebaseAuth.instance.currentUser!.uid)
          .get();

      // Fetch documents in the 'sos' collection
      QuerySnapshot sosQuerySnapshot = await FirebaseFirestore.instance
          .collection('sos')
          .where('responders',
              arrayContains: FirebaseAuth.instance.currentUser!.uid)
          .get();

      int incidentsResponded = 0;

      // Function to process each document in a collection
      Future<void> processDocuments(QuerySnapshot querySnapshot) async {
        for (QueryDocumentSnapshot doc in querySnapshot.docs) {
          DocumentSnapshot respondersDocSnapshot = await FirebaseFirestore
              .instance
              .collection(
                  doc.reference.parent.id) // Dynamically get collection name
              .doc(doc.id)
              .collection('responders')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get();

          if (respondersDocSnapshot.exists &&
              respondersDocSnapshot.data() != null) {
            Map<String, dynamic> respondersData =
                respondersDocSnapshot.data() as Map<String, dynamic>;
            if (respondersData['status'] == 'Responded') {
              incidentsResponded++;
            }
          }
        }
      }

      // Process both 'incidents' and 'sos' collections
      await processDocuments(incidentQuerySnapshot);
      await processDocuments(sosQuerySnapshot);

      return incidentsResponded;
    } catch (e) {
      print('Error checking incidents: $e');
      return 0;
    }
  }
}
