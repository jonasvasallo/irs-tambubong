import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_capstone/constants.dart';
import 'package:irs_capstone/utilities.dart';
import 'package:irs_capstone/widgets/input_button.dart';

class VerifyPhonePage extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  const VerifyPhonePage(
      {Key? key, required this.verificationId, required this.phoneNumber})
      : super(key: key);

  @override
  State<VerifyPhonePage> createState() => _VerifyPhonePageState();
}

class _VerifyPhonePageState extends State<VerifyPhonePage> {
  TextEditingController firstNum = TextEditingController();
  TextEditingController secondNum = TextEditingController();
  TextEditingController thirdNum = TextEditingController();
  TextEditingController fourthNum = TextEditingController();
  TextEditingController fifthNum = TextEditingController();
  TextEditingController sixthNum = TextEditingController();

  final _firstFocusNode = FocusNode();

  late bool isResendButtonEnabled;
  late Timer resendTimer;

  int minutesLeft = 5;
  int secondsLeft = 0;
  String timeLeft = "";

  void startTimer() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (secondsLeft == 0 && minutesLeft == 0) {
          timer.cancel();
        }
        if (secondsLeft > 0) {
          secondsLeft--;
        } else {
          minutesLeft--;
          secondsLeft = 59;
        }
        String strMinutes = minutesLeft.toString();
        String strSeconds = secondsLeft.toString();

        if (strMinutes.length < 2) {
          strMinutes = "0$strMinutes";
        }
        if (strSeconds.length < 2) {
          strSeconds = "0$strSeconds";
        }
        timeLeft = "$strMinutes:$strSeconds";
      });
    });
  }

  Future resentOTP() async {
    if (!isResendButtonEnabled) {
      return;
    }

    startTimer();
    setState(() {
      isResendButtonEnabled = false;
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      verificationCompleted: (PhoneAuthCredential credential) async {},
      verificationFailed: (FirebaseAuthException ex) {
        print(ex);
      },
      codeSent: (String verificationId, int? resendToken) async {
        Utilities.showSnackBar("SMS sent successfully", Colors.green);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
      phoneNumber: widget.phoneNumber,
    );

    resendTimer = Timer(Duration(minutes: 5), () {
      setState(() {
        isResendButtonEnabled = true;
      });
    });
  }

  @override
  void initState() {
    super.initState();

    _firstFocusNode.requestFocus();

    isResendButtonEnabled = true;
    resendTimer = Timer(Duration(minutes: 5), () {
      setState(() {
        isResendButtonEnabled = true;
      });
    });
  }

  @override
  void dispose() {
    _firstFocusNode.dispose();
    firstNum.dispose();
    secondNum.dispose();
    thirdNum.dispose();
    fourthNum.dispose();
    fifthNum.dispose();
    sixthNum.dispose();
    resendTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 205,
                height: 205,
                color: Colors.grey,
              ),
              SizedBox(
                height: 32,
              ),
              Text(
                "Phone Verification",
                style: TextStyle(
                  color: majorText,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                height: 8,
              ),
              Column(
                children: [
                  Text(
                    "Please enter the verification code sent to",
                    style: CustomTextStyle.regular_minor,
                  ),
                  Text(
                    widget.phoneNumber,
                    style: TextStyle(
                        color: majorText,
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
                  ),
                ],
              ),
              SizedBox(
                height: 32,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  VerifyField(
                    controller: firstNum,
                    focusNode: _firstFocusNode,
                  ),
                  VerifyField(
                    controller: secondNum,
                  ),
                  VerifyField(
                    controller: thirdNum,
                  ),
                  VerifyField(
                    controller: fourthNum,
                  ),
                  VerifyField(
                    controller: fifthNum,
                  ),
                  VerifyField(
                    controller: sixthNum,
                  ),
                ],
              ),
              SizedBox(
                height: 64,
              ),
              Text(
                "Didn't receive the code?",
                style: CustomTextStyle.regular_minor,
              ),
              TextButton(
                onPressed: isResendButtonEnabled ? resentOTP : null,
                child: Text(
                  "RESEND CODE",
                  style: TextStyle(
                    color: isResendButtonEnabled ? accentColor : Colors.grey,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                timeLeft,
                style: TextStyle(
                  fontSize: 14,
                  color: minorText,
                ),
              ),
              SizedBox(
                height: 34,
              ),
              InputButton(
                  label: "VERIFY",
                  function: () async {
                    try {
                      String codeSMS = firstNum.text.toString() +
                          secondNum.text.toString() +
                          thirdNum.text.toString() +
                          fourthNum.text.toString() +
                          fifthNum.text.toString() +
                          sixthNum.text.toString();
                      PhoneAuthCredential credential =
                          PhoneAuthProvider.credential(
                        verificationId: widget.verificationId,
                        smsCode: codeSMS,
                      );
                      User? emailPasswordUser =
                          FirebaseAuth.instance.currentUser;

                      if (emailPasswordUser != null) {
                        // Link the email/password user with the phone number credential
                        UserCredential result = await emailPasswordUser
                            .linkWithCredential(credential);

                        // Check if the linking was successful
                        if (result.user != null) {
                          // Update the 'verified' field in the user's document in Firestore
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(result.user!.uid)
                              .update({'verified': true});

                          // Navigate to the home screen or any other destination
                          context.go('/home');
                        } else {
                          print('Linking failed: User is null');
                          // Handle failed linking, show an error message, etc.
                        }
                      }
                    } catch (ex) {
                      print(ex);
                    }
                  },
                  large: true),
            ],
          ),
        ),
      ),
    );
  }
}

class VerifyField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  const VerifyField({
    Key? key,
    required this.controller,
    this.focusNode,
  }) : super(key: key);

  @override
  State<VerifyField> createState() => _VerifyFieldState();
}

class _VerifyFieldState extends State<VerifyField> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: 50,
      child: TextFormField(
        focusNode: widget.focusNode,
        onChanged: (value) {
          if (value.length == 1) {
            setState(() {
              widget.controller.text = value;
            });
            FocusScope.of(context).nextFocus();
          }
        },
        onSaved: (newValue) {},
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: majorText,
        ),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(8),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Color(0xFFF3F4F4),
        ),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
      ),
    );
  }
}
