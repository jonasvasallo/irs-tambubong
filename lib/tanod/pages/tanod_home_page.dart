import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/widgets/incident_container.dart';

class TanodHomePage extends StatefulWidget {
  const TanodHomePage({Key? key}) : super(key: key);

  @override
  _TanodHomePageState createState() => _TanodHomePageState();
}

class _TanodHomePageState extends State<TanodHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            FutureBuilder(
                future: FirebaseFirestore.instance
                    .collection('users')
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

                  final userDetails = snapshot.data!;

                  return UserAccountsDrawerHeader(
                    currentAccountPicture: CircleAvatar(
                      backgroundImage:
                          NetworkImage(userDetails['profile_path']),
                    ),
                    accountName: Text(
                        "${userDetails['first_name']} ${userDetails['last_name']}"),
                    accountEmail: Text("${userDetails['email']}"),
                  );
                }),
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text("Profile"),
              onTap: () {
                context.go('/tanod_home/profile');
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text("Response History"),
              onTap: () {
                context.go('/tanod_home/response-history');
              },
            ),
            ListTile(
              leading: Icon(Icons.logout_outlined),
              title: Text("Logout"),
              onTap: () {
                FirebaseAuth.instance.signOut();
                context.go('/login');
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text("Incidents"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('incidents')
                  .where('responders',
                      arrayContains: FirebaseAuth.instance.currentUser!.uid)
                  .where(
                'status',
                whereNotIn: ['Resolved', 'Closed'],
              ).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(); // Placeholder for loading state
                }
                if (snapshot.hasError) {
                  print("${snapshot.error}");
                  return Text(
                      'Error: ${snapshot.error}'); // Placeholder for error state
                }
                final docs = snapshot.data?.docs ?? [];
                return Column(
                  children: docs.map((doc) {
                    return GestureDetector(
                      onTap: () {
                        context.go('/tanod_home/incident-details/${doc.id}');
                        print("test");
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      flex: 3,
                                      child: Text(
                                        doc['title'],
                                        overflow: TextOverflow.ellipsis,
                                        style: CustomTextStyle.subheading,
                                      ),
                                    ),
                                    Text(
                                      Utilities.convertDate(doc['timestamp']),
                                      overflow: TextOverflow.ellipsis,
                                      style: CustomTextStyle.regular,
                                    ),
                                  ],
                                ),
                                Text(
                                  doc['details'],
                                  overflow: TextOverflow.ellipsis,
                                  style: CustomTextStyle.regular_minor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
        ),
      ),
    );
  }
}
