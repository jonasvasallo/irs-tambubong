import 'package:flutter/material.dart';
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
}
