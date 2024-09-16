import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/input_validator.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/widgets/input_button.dart';
import 'package:irs_app/widgets/input_field.dart';
import 'package:irs_app/widgets/sos_send_chat_field.dart';

class OngoingSosPage extends StatefulWidget {
  final String id;
  const OngoingSosPage({Key? key, required this.id}) : super(key: key);

  @override
  _OngoingSosPageState createState() => _OngoingSosPageState();
}

class _OngoingSosPageState extends State<OngoingSosPage> {
  void endSos() async {
    try {
      DocumentReference documentReference =
          await FirebaseFirestore.instance.collection('sos').doc(widget.id);
      documentReference.update({
        'status': 'Cancelled',
      });
      context.go('/sos');
    } catch (ex) {
      Utilities.showSnackBar("$ex", Colors.red);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: SizedBox(),
        title: Text("Ongoing SOS"),
        actions: [],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('sos')
            .doc(widget.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Text("Error ${snapshot.error}");
          }

          DocumentSnapshot<Map<String, dynamic>> sosDocument = snapshot.data!;
          Map<String, dynamic> sosData = sosDocument.data()!;
          LatLng location = LatLng(sosDocument['location']['latitude'],
              sosDocument['location']['longitude']);
          String userId = sosDocument['user_id'];
          String status = sosDocument['status'].toString().toLowerCase();

          if (status == 'resolved' ||
              status == 'closed' ||
              status == 'cancelled' ||
              status == 'dismissed') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pop();
            });
          }
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey,
                  child: GoogleMap(
                    initialCameraPosition:
                        CameraPosition(target: location, zoom: 18),
                    circles: Set.from([
                      Circle(
                        circleId: CircleId("sosPosition"),
                        center: location,
                        radius: 8,
                        fillColor: Color.fromARGB(255, 255, 0, 0),
                        strokeColor: Color.fromARGB(255, 109, 0, 0),
                        strokeWidth: 2,
                      )
                    ]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "SOS Chatroom",
                    style: CustomTextStyle.subheading,
                  ),
                ),
                Expanded(
                  child: StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('sos')
                          .doc(widget.id)
                          .collection('chatroom')
                          .orderBy('timestamp', descending: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error ${snapshot.error}');
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Text("No messages yet."),
                          );
                        }

                        List<Widget> chatWidgets = [];
                        final messages = snapshot.data?.docs.toList();
                        for (var message in messages!) {
                          final Widget chatWidget;
                          if (message['sent_by'] ==
                              FirebaseAuth.instance.currentUser?.uid) {
                            chatWidget = Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: EdgeInsets.only(top: 4, bottom: 4),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: accentColor,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      message['content'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          } else {
                            chatWidget = Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(top: 4, bottom: 4),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: minorText,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      message['content'],
                                      style: CustomTextStyle.regular,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          chatWidgets.add(chatWidget);
                        }
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: chatWidgets,
                            ),
                          ),
                        );
                      }),
                ),
                SosSendChatField(id: widget.id),
              ],
            ),
          );
        },
      ),
    );
  }
}
