import "package:flutter/material.dart";

const accentColor = Color(0xFF625BDD);
const tintColor = Color(0xFFFFDA93);
const majorText = Color(0xFF37353B);
const minorText = Color(0xFFA2A2A2);
const scaffoldBg = Color(0xFFFFFFFF);

const padding16 = EdgeInsets.all(16);
const padding8 = EdgeInsets.all(8);
const padding4 = EdgeInsets.all(4);
const padding_only16 = EdgeInsets.only(top: 16, bottom: 16);
const padding_only8 = EdgeInsets.only(top: 8, bottom: 8);
const padding_only4 = EdgeInsets.only(top: 4, bottom: 4);

class CustomTextStyle {
  static TextStyle heading = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 20,
    color: majorText,
  );

  static TextStyle subheading = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 18,
    color: majorText,
  );

  static TextStyle regular = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 16,
    color: majorText,
  );

  static TextStyle regular_minor = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 16,
    color: minorText,
  );
}
