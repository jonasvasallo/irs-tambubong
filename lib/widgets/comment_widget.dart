import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:irs_capstone/constants.dart';

class CommentWidget extends StatefulWidget {
  final String uid;
  final String comment;
  const CommentWidget({Key? key, required this.uid, required this.comment})
      : super(key: key);

  @override
  _CommentWidgetState createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future:
          FirebaseFirestore.instance.collection('users').doc(widget.uid).get(),
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

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(48),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(48),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${userDetails['first_name']} ${userDetails['last_name']}",
                      style: CustomTextStyle.regular,
                    ),
                    Text(
                      "${widget.comment}",
                      style: CustomTextStyle.regular_minor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
