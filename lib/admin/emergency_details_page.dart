import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/widgets/add_responder_dialog.dart';
import 'package:irs_app/widgets/emergency_video_part.dart';
import 'package:irs_app/widgets/input_button.dart';
import 'package:irs_app/widgets/responder_remove_container.dart';
import 'package:video_player/video_player.dart';

class EmergencyDetailsPage extends StatefulWidget {
  final String id;
  const EmergencyDetailsPage({Key? key, required this.id}) : super(key: key);

  @override
  _EmergencyDetailsPageState createState() => _EmergencyDetailsPageState();
}

class _EmergencyDetailsPageState extends State<EmergencyDetailsPage> {
  String _dropdownValue = "";

  void saveStatus() async {
    if (_dropdownValue.isEmpty || _dropdownValue == null) {
      Utilities.showSnackBar("Please select a status first!", Colors.red);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('sos').doc(widget.id).update({
        'status': _dropdownValue,
      });
      setState(() {
        _dropdownValue = "";
      });
      Utilities.showSnackBar("Successfully updated status", Colors.green);
    } catch (err) {
      Utilities.showSnackBar("${err}", Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Emergency Request"),
      ),
      body: SingleChildScrollView(
        padding: padding16,
        child: FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('sos')
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

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(
                  child: Text("No data available."),
                );
              }

              // Document snapshot
              var document = snapshot.data!;
              var data = document.data() as Map<String, dynamic>?;

              if (data == null) {
                return Center(
                  child: Text("Document has no data."),
                );
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SOS Call by",
                    style: CustomTextStyle.subheading,
                  ),
                  FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(data['user_id'])
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

                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return Center(
                            child: Text("No data available."),
                          );
                        }

                        // Document snapshot
                        var document = snapshot.data!;
                        var userdata = document.data() as Map<String, dynamic>?;

                        if (userdata == null) {
                          return Center(
                            child: Text("Document has no data."),
                          );
                        }
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: Image.network(
                                      userdata['profile_path'],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 8,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        "${userdata['first_name']} ${userdata['last_name']}"),
                                    Text("${userdata['contact_no']}"),
                                    Row(
                                      children: [
                                        Container(
                                          padding: padding8,
                                          color: (userdata['verified'])
                                              ? Color.fromARGB(
                                                  255, 224, 255, 225)
                                              : Color.fromARGB(
                                                  255, 255, 224, 224),
                                          child: Text(
                                            "${(userdata['verified']) ? 'Verified' : 'Not Verified'}",
                                            style: TextStyle(
                                              color: (userdata['verified'])
                                                  ? Color.fromARGB(
                                                      255, 35, 255, 42)
                                                  : Color.fromARGB(
                                                      255, 184, 0, 0),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 8,
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            if (userdata[
                                                    'verification_photo'] ==
                                                null) {
                                              Utilities.showSnackBar(
                                                  "This user does not have an ID attached!",
                                                  Colors.red);
                                              return;
                                            }
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  content: Padding(
                                                    padding: padding16,
                                                    child: SizedBox(
                                                      width: 200,
                                                      height: 300,
                                                      child: Image.network(
                                                        userdata[
                                                            'verification_photo'],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                          child: Text("View ID"),
                                        ),
                                      ],
                                    )
                                  ],
                                )
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    await FlutterPhoneDirectCaller.callNumber(
                                        "${userdata['contact_no']}");
                                  },
                                  icon: Icon(Icons.call),
                                ),
                                IconButton(
                                  onPressed: () {},
                                  icon: Icon(Icons.message),
                                ),
                              ],
                            )
                          ],
                        );
                      }),
                  EmergencyVideoPart(path: data['attachment']),
                  SizedBox(
                    height: 16,
                  ),
                  // Container(
                  //   width: MediaQuery.of(context).size.width - 32,
                  //   height: 60,
                  //   color: Colors.amber,
                  // ),
                  // SizedBox(
                  //   height: 16,
                  // ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Update Status",
                        style: CustomTextStyle.regular,
                      ),
                      DropdownMenu(
                        onSelected: (value) {
                          _dropdownValue = value as String;
                        },
                        initialSelection: data['status'],
                        width: MediaQuery.of(context).size.width - 32,
                        dropdownMenuEntries: [
                          DropdownMenuEntry(
                            value: "Active",
                            label: "Active",
                          ),
                          DropdownMenuEntry(
                            value: "Handling",
                            label: "Handling",
                          ),
                          DropdownMenuEntry(
                            value: "Resolved",
                            label: "Resolved",
                          ),
                          DropdownMenuEntry(
                            value: "Closed",
                            label: "Closed",
                          ),
                          DropdownMenuEntry(
                            value: "Dismissed",
                            label: "Dismissed",
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: InputButton(
                          label: "Update",
                          function: saveStatus,
                          large: false,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Responders",
                          ),
                          TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AddResponderDialog(
                                    id: widget.id,
                                    responders: data['responders'],
                                    latitude: data['location']['latitude'],
                                    longitude: data['location']['longitude'],
                                  );
                                },
                              );
                            },
                            child: Text("Add"),
                          ),
                        ],
                      ),
                      StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('sos')
                            .doc(widget.id)
                            .snapshots(),
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

                          if (!snapshot.hasData) {
                            return Center(
                              child: Text("No data available."),
                            );
                          }

                          // Extract the document data
                          var incidentData =
                              snapshot.data!.data() as Map<String, dynamic>;

                          // Access the 'responders' field (array of user IDs)
                          List<String> responders = List<String>.from(
                              incidentData['responders'] ?? []);

                          return Column(
                            children: [
                              if (responders.isEmpty)
                                Text("No responders assigned yet."),
                              ...responders.map((responderId) {
                                return ResponderRemoveContainer(
                                  id: widget.id,
                                  uid: responderId,
                                  // Pass the responder ID to the container
                                );
                              }).toList(),
                            ],
                          );
                        },
                      )
                    ],
                  ),
                ],
              );
            }),
      ),
    );
  }
}
