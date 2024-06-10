import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/input_validator.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/widgets/input_button.dart';
import 'package:irs_app/widgets/input_field.dart';

class TanodEmergencyChatroomPage extends StatefulWidget {
  final String id;
  const TanodEmergencyChatroomPage({Key? key, required this.id})
      : super(key: key);

  @override
  _TanodEmergencyChatroomPageState createState() =>
      _TanodEmergencyChatroomPageState();
}

class _TanodEmergencyChatroomPageState
    extends State<TanodEmergencyChatroomPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chatroom"),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 8,
                child: SingleChildScrollView(
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
                            chatWidget = FutureBuilder(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(message['sent_by'])
                                    .get(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return Text("No Message");
                                  }
                                  final userDetails = snapshot.data!;

                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding:
                                          EdgeInsets.only(top: 4, bottom: 4),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            height: 48,
                                            width: 48,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(48),
                                              child: Image.network(
                                                userDetails['profile_path'],
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 8,
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${userDetails['first_name']} ${userDetails['last_name']}",
                                                style: CustomTextStyle.regular,
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  color: minorText,
                                                ),
                                                child: Padding(
                                                  padding: EdgeInsets.all(8),
                                                  child: Text(
                                                    message['content'],
                                                    style:
                                                        CustomTextStyle.regular,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                });
                          }
                          chatWidgets.add(chatWidget);
                        }
                        return Column(
                          children: chatWidgets,
                        );
                      }),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: InputField(
                      placeholder: "Type your message here...",
                      inputType: "text",
                      controller: _messageController,
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
            ],
          ),
        ),
      ),
    );
  }
}
