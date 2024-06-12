import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:irs_app/constants.dart";
import "package:irs_app/core/utilities.dart";
import "package:irs_app/widgets/notification_tile.dart";

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
      ),
      body: SingleChildScrollView(
        padding: padding16,
        child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("users")
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .collection("notifications")
                .orderBy("timestamp", descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error ${snapshot.error}');
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text("No notifications yet."),
                );
              }
              List<Widget> notificationWidgets = [];
              final notificationList = snapshot.data?.docs.toList();

              for (var notification in notificationList!) {
                notificationWidgets.add(
                  GestureDetector(
                    onTap: () {
                      context.go('/notifications/${notification.id}');
                    },
                    child: NotificationTile(
                      id: notification.id,
                      title: notification['title'],
                      body: notification['content'],
                      date: Utilities.convertDate(
                        notification['timestamp'],
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: notificationWidgets,
              );
            }),
      ),
    );
  }
}
