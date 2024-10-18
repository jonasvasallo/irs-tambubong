import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:irs_app/constants.dart';
import 'package:url_launcher/url_launcher.dart';

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

  static void launchURL(Uri uri, bool inApp) async{
    try{
      if(await canLaunchUrl(uri)){
        if(inApp){
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
        } else{
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else{
        showSnackBar("Cannot launch URL", Colors.red);
      }
    } catch(e){
      print(e.toString());
      showSnackBar(e.toString(), Colors.red);
    }
  }
}
