import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/input_validator.dart';
import 'package:irs_app/core/utilities.dart';
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
