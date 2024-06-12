import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:irs_app/constants.dart";
import "package:irs_app/core/utilities.dart";

class NotificationDetailPage extends StatefulWidget {
  final String id;
  const NotificationDetailPage({Key? key, required this.id}) : super(key: key);

  @override
  _NotificationDetailPageState createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends State<NotificationDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notification Details"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: padding16,
          child: FutureBuilder(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection("notifications")
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
                    child: Text("Notification not found."),
                  );
                }

                final notificationDetails =
                    snapshot.data!.data() as Map<String, dynamic>?;

                if (notificationDetails == null) {
                  return Center(
                    child: Text("No data available."),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${notificationDetails['title']}",
                      style: CustomTextStyle.subheading,
                    ),
                    Text(
                      "${Utilities.convertDate(notificationDetails['timestamp'])}",
                      style: CustomTextStyle.regular_minor,
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Text(
                      "${notificationDetails['content']}",
                      style: CustomTextStyle.regular,
                    )
                  ],
                );
              }),
        ),
      ),
    );
  }
}
