import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/input_validator.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/widgets/input_button.dart';
import 'package:irs_app/widgets/input_field.dart';

class OngoingSosPage extends StatefulWidget {
  final String id;
  const OngoingSosPage({Key? key, required this.id}) : super(key: key);

  @override
  _OngoingSosPageState createState() => _OngoingSosPageState();
}

class _OngoingSosPageState extends State<OngoingSosPage> {
  final _messageController = TextEditingController();

  void sendMessage() async {
    if (_messageController.text.isEmpty) {
      Utilities.showSnackBar("Please enter a message", Colors.red);
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('sos')
          .doc(widget.id)
          .collection('chatroom')
          .add({
        'content': _messageController.text.trim(),
        'sent_by': FirebaseAuth.instance.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
      });
      setState(() {
        _messageController.text = "";
      });
    } catch (ex) {
      Utilities.showSnackBar("$ex", Colors.red);
    }
  }

  void endSos() async {
    try {
      DocumentReference documentReference =
          await FirebaseFirestore.instance.collection('sos').doc(widget.id);
      documentReference.update({
        'status': 'Cancelled',
      });
      Navigator.of(context).pop();
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
        leading: Icon(
          Icons.warning,
          color: Colors.red,
        ),
        title: Text("Ongoing SOS"),
        actions: [
          TextButton(
            onPressed: () {
              endSos();
            },
            child: Text(
              "End",
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
            return SafeArea(
                child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            "Chatroom",
                            style: CustomTextStyle.subheading,
                          ),
                        ),
                        Flexible(
                          fit: FlexFit.loose,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
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
                                        FirebaseAuth
                                            .instance.currentUser?.uid) {
                                      chatWidget = Align(
                                        alignment: Alignment.centerRight,
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              top: 4, bottom: 4),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                          padding: EdgeInsets.only(
                                              top: 4, bottom: 4),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                  return Column(
                                    children: chatWidgets,
                                  );
                                }),
                          ),
                        ),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: InputField(
                                  placeholder: "Type your message here...",
                                  inputType: "text",
                                  controller: _messageController,
                                  validator: InputValidator.requiredValidator,
                                ),
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 24),
                                  child: InputButton(
                                      label: "Send",
                                      function: () {
                                        sendMessage();
                                      },
                                      large: false),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ));
          }),
    );
  }
}
