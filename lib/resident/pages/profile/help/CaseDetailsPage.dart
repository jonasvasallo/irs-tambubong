import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:irs_app/constants.dart";
import "package:irs_app/core/input_validator.dart";
import "package:irs_app/core/rate_limiter.dart";
import "package:irs_app/core/utilities.dart";
import "package:irs_app/widgets/input_button.dart";
import "package:irs_app/widgets/input_field.dart";

class CaseDetailsPage extends StatefulWidget {
  final String id;
  const CaseDetailsPage({Key? key, required this.id}) : super(key: key);

  @override
  _CaseDetailsPageState createState() => _CaseDetailsPageState();
}

class _CaseDetailsPageState extends State<CaseDetailsPage> {
  final _replyController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  void sendReply() async {
    final isValid = formKey.currentState!.validate();
    if (!isValid) {
      return;
    }

    final RateLimiter _rateLimiter = RateLimiter(userId: FirebaseAuth.instance.currentUser!.uid, keyPrefix: 'action', cooldownDuration: Duration(seconds: 5),);
    if (!await _rateLimiter.isActionAllowed()) {
      Utilities.showSnackBar("You are doing this action way too quickly!", Colors.red);
      return;
    }

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

    await _rateLimiter.updateLastActionTime();

    try {
      await FirebaseFirestore.instance
          .collection('help')
          .doc(widget.id)
          .collection('replies')
          .add({
        'content': _replyController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'user_id': FirebaseAuth.instance.currentUser!.uid,
      });

      formKey.currentState!.reset();
      _replyController.clear();
    } catch (error) {
      print(error);
      Utilities.showSnackBar("${error}", Colors.red);
    }

    Navigator.pop(dialogContext);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Case Details"),
      ),
      body: SingleChildScrollView(
        padding: padding16,
        child: FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('help')
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

              final caseDetails = snapshot.data!.data() as Map<String, dynamic>;
              String myDate = "test";

              if (caseDetails['timestamp'] != null) {
                Timestamp t = caseDetails['timestamp'] as Timestamp;
                DateTime date = t.toDate();
                myDate = DateFormat('EEE, MMMM dd, y, hh:mm aa').format(date);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Case ${widget.id}: ${caseDetails['title']}",
                    style: CustomTextStyle.heading,
                  ),
                  FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(caseDetails['created_by'])
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text("");
                        }
                        if (snapshot.hasError) {
                          return Text("${snapshot.error}");
                        }

                        final userDetails =
                            snapshot.data!.data() as Map<String, dynamic>;

                        return Text(
                          "Created by ${userDetails['first_name']} ${userDetails['last_name']} <${userDetails['email']}> for ${caseDetails['title']} on ${myDate}",
                        );
                      }),
                  SizedBox(
                    height: 8,
                  ),
                  Text("Case Description"),
                  Text(
                    "${caseDetails['description']}",
                    style: CustomTextStyle.regular,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Divider(
                    color: minorText,
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  (caseDetails['status'] == 'Open')
                      ? Row(
                          children: [
                            Icon(Icons.check_circle_outline),
                            SizedBox(
                              width: 8,
                            ),
                            Text(caseDetails['status']),
                          ],
                        )
                      : Row(
                          children: [
                            Icon(Icons.remove_circle_outline),
                            SizedBox(
                              width: 8,
                            ),
                            Text(caseDetails['status']),
                          ],
                        ),
                  SizedBox(
                    height: 16,
                  ),
                  Divider(
                    color: minorText,
                  ),
                  (caseDetails['status'] == "Closed")
                      ? SizedBox()
                      : Form(
                          key: formKey,
                          child: Column(
                            children: [
                              InputField(
                                placeholder: "Reply",
                                inputType: "message",
                                controller: _replyController,
                                validator: InputValidator.requiredValidator,
                              ),
                              SizedBox(
                                height: 8,
                              ),
                              InputButton(
                                label: "Send",
                                function: () => sendReply(),
                                large: false,
                              ),
                            ],
                          ),
                        ),
                  SizedBox(
                    height: 16,
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('help')
                        .doc(widget.id)
                        .collection('replies')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Text("No conversation yet.");
                      }

                      if (snapshot.data!.docs.isEmpty) {
                        return Text("No conversation yet.");
                      }

                      List<Widget> replyWidgets = [];
                      final replyDocs = snapshot.data!.docs.toList();

                      for (var replyDoc in replyDocs) {
                        String myDate = "test";

                        if (replyDoc['timestamp'] != null) {
                          Timestamp t = replyDoc['timestamp'] as Timestamp;
                          DateTime date = t.toDate();
                          myDate =
                              DateFormat('EEE, MM/dd/y, hh:mm aa').format(date);
                        }

                        final replyWidget = FutureBuilder(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(replyDoc['user_id'])
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

                              final userDetails =
                                  snapshot.data!.data() as Map<String, dynamic>;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
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
                                          userDetails['profile_path'],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 8,
                                    ),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              "${userDetails['first_name']} ${userDetails['last_name']}"),
                                          Text(
                                            myDate,
                                          ),
                                          Text(
                                            "${replyDoc['content']}",
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              );
                            });

                        replyWidgets.add(replyWidget);
                      }

                      return Column(
                        children: replyWidgets,
                      );
                    },
                  )
                ],
              );
            }),
      ),
    );
  }
}
