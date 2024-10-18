import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/input_validator.dart';
import 'package:irs_app/core/rate_limiter.dart';
import 'package:irs_app/core/status_checker.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/models/user_model.dart';
import 'package:irs_app/widgets/input_button.dart';
import 'package:irs_app/widgets/input_field.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({Key? key}) : super(key: key);

  @override
  _HelpPageState createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  void fileCase() async {
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

    final status_checker = StatusChecker();
    final hasActiveIncident = await status_checker.hasActiveDocument(
      collectionName: 'help',         // Collection to search
      userIdField: 'created_by',               // Field in the document that matches the user
      userId: FirebaseAuth.instance.currentUser!.uid,                      // Current logged-in user's ID
      statusField: 'status',               // Field to check the status
      activeStatuses: ['Open'],  // List of active statuses
    );

    if(hasActiveIncident){
      Navigator.pop(dialogContext);
      Utilities.showSnackBar("You currently have an active ticket!", Colors.red);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('help').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'created_by': FirebaseAuth.instance.currentUser!.uid,
        'status': 'Open',
      });

      Utilities.showSnackBar("Successfully submitted ticket", Colors.green);

      formKey.currentState!.reset();
      _titleController.clear();
      _descriptionController.clear();
    } catch (error) {
      print(error);
      Utilities.showSnackBar("${error}", Colors.red);
    }

    Navigator.pop(dialogContext);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Help"),
          bottom: const TabBar(
            tabs: [
              Tab(
                child: Text("Submit Ticket Form"),
              ),
              Tab(
                child: Text("Your Cases"),
              ),
            ],
          ),
          actions: [
            IconButton(onPressed: () => Utilities.launchURL(Uri.parse("https://youtu.be/BAhbqZeUmhc?si=Gsx0UkbY1e9WLQu9&t=366"), true), icon: Icon(Icons.help_outline_rounded),),
          ],
        ),
        body: TabBarView(
          children: [
            Form(
              key: formKey,
              child: SingleChildScrollView(
                padding: padding16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "How can we help?",
                      style: CustomTextStyle.heading,
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    InputField(
                      placeholder: "Subject",
                      inputType: "text",
                      controller: _titleController,
                      validator: InputValidator.requiredValidator,
                    ),
                    InputField(
                      placeholder: "Message",
                      inputType: "message",
                      controller: _descriptionController,
                      validator: InputValidator.requiredValidator,
                    ),
                    InputButton(
                      label: "Submit",
                      function: fileCase,
                      large: true,
                    ),
                  ],
                ),
              ),
            ),
            SingleChildScrollView(
              padding: padding16,
              child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('help')
                      .where('created_by',
                          isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      print("this happened");
                      return Center(
                        child: Text("No cases yet."),
                      );
                    }
                    if (snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text("No cases yet."),
                      );
                    }

                    List<Widget> casesWidgets = [];
                    final casesDocs = snapshot.data!.docs.toList();
                    for (var caseDoc in casesDocs) {
                      String myDate = "test";

                      if (caseDoc['timestamp'] != null) {
                        Timestamp t = caseDoc['timestamp'] as Timestamp;
                        DateTime date = t.toDate();
                        myDate = DateFormat('MMMM dd, y').format(date);
                      }

                      casesWidgets.add(ListTile(
                        onTap: () =>
                            context.go('/profile/help/details/${caseDoc.id}'),
                        title: Text(
                          "${caseDoc['title']}",
                          style: CustomTextStyle.subheading,
                        ),
                        subtitle: Text("${caseDoc['status']}"),
                        trailing: Text(myDate),
                      ));
                    }
                    return Column(
                      children: casesWidgets,
                    );
                  }),
            )
          ],
        ),
      ),
    );
  }
}
