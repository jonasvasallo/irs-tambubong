import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/widgets/input_button.dart';
import 'package:irs_app/widgets/input_field.dart';

class MfaPhonePage extends StatefulWidget {
  final String id;
  const MfaPhonePage({Key? key, required this.id}) : super(key: key);

  @override
  _MfaPhonePageState createState() => _MfaPhonePageState();
}

class _MfaPhonePageState extends State<MfaPhonePage>
    with WidgetsBindingObserver {
  final TextEditingController _codeController = TextEditingController();
  String? generatedCode;
  bool _isCodeSent = false;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      await FirebaseAuth.instance.signOut();
    }
  }

  void verifyCode() async {
    try {
      String codeSMS = _codeController.text.toString();
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.id,
        smsCode: codeSMS,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      context.go('/home');
    } on FirebaseAuthException catch (ex) {
      print(ex);
      if (ex.code == 'invalid-verification-code') {
        Utilities.showSnackBar("The OTP entered was invalid", Colors.red);
      } else if (ex.code == 'session-expired') {
        Utilities.showSnackBar(
            "The SMS code has expired. Please re-send the verification code to try again",
            Colors.red);
      } else {
        Utilities.showSnackBar("${ex.message}", Colors.red);
      }
    }
  }

  void resendOTP() async {
    context.go('/mfa');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Phone OTP"),
        leading: IconButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            context.go('/login');
          },
          icon: Icon(
            Icons.chevron_left_rounded,
          ),
        ),
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: Padding(
            padding: padding16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Verification code sent",
                  style: CustomTextStyle.subheading,
                ),
                Text(
                  "A code has been sent to your registered phone number ${FirebaseAuth.instance.currentUser!.phoneNumber}",
                ),
                InputField(
                  placeholder: "6-digit code here",
                  inputType: "text",
                  controller: _codeController,
                ),
                InputButton(
                  label: "Continue",
                  function: () {
                    verifyCode();
                  },
                  large: true,
                ),
                SizedBox(
                  height: 16,
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive the code?",
                      ),
                      TextButton(
                        onPressed: resendOTP,
                        child: Text("Resend"),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
