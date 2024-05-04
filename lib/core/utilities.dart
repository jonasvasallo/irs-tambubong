import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:irs_capstone/constants.dart';

class Utilities {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();
  static showSnackBar(String? text, MaterialColor color) {
    if (text == null) return;

    final snackBar = SnackBar(
      content: Text(
        text,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );

    messengerKey.currentState!
      ..removeCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static BuildContext showLoadingIndicator(context) {
    BuildContext dialogContext = context;
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (dialogcontext) {
          dialogContext = dialogcontext;
          return Center(
            child: CircularProgressIndicator(
              color: accentColor,
            ),
          );
        });

    return dialogContext;
  }

  static String convertDate(dynamic daters) {
    Timestamp t = daters as Timestamp;
    DateTime date = t.toDate();
    return DateFormat('MMMM dd - hh:mm a').format(date);
  }
}
