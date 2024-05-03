import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_capstone/constants.dart';

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
                            Text(
                              "696969",
                              style: CustomTextStyle.subheading,
                            ),
                            Text(
                              "Responded",
                              style: CustomTextStyle.regular,
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              "4.5",
                              style: CustomTextStyle.subheading,
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
                        "Badges earned",
                        style: CustomTextStyle.subheading,
                      ),
                    ),
                    SizedBox(
                      height: 24,
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: Column(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(80),
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  "69",
                                  style: CustomTextStyle.subheading,
                                ),
                                Text(
                                  "Excellent Service",
                                  style: CustomTextStyle.regular,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(80),
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                "69",
                                style: CustomTextStyle.subheading,
                              ),
                              Text(
                                "Excellent Service",
                                style: CustomTextStyle.regular,
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(80),
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                "69",
                                style: CustomTextStyle.subheading,
                              ),
                              Text(
                                "Excellent Service",
                                style: CustomTextStyle.regular,
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                );
              }),
        ),
      ),
    );
  }
}
