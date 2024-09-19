import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/widgets/input_button.dart';

class MfaPage extends StatefulWidget {
  const MfaPage({Key? key}) : super(key: key);

  @override
  _MfaPageState createState() => _MfaPageState();
}

class _MfaPageState extends State<MfaPage> with WidgetsBindingObserver {
  bool _verifying = false;
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
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.hidden && _verifying == false) {
      print("value before sign out ${_verifying}");
      await FirebaseAuth.instance.signOut();
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Two-factor Authentication"),
      ),
      body: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Padding(
          padding: padding16,
          child: Column(
            children: [
              Text(
                "Two-factor authentication is enabled",
                style: CustomTextStyle.subheading,
              ),
              SizedBox(
                height: 8,
              ),
              Text(
                "Your account has 2FA enabled. This provides an additional layer of security when signing in to your account.",
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 16,
              ),
              SizedBox(height: 8),
              Container(
                padding: padding16,
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 242, 247, 248),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: padding8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Color.fromARGB(255, 7, 205, 255),
                          ),
                          child: Icon(
                            Icons.email_rounded,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Text("Phone"),
                      ],
                    ),
                    TextButton(
                      onPressed: () async {
                        _verifying = true;
                        print(_verifying);
                        try {
                          await FirebaseAuth.instance.verifyPhoneNumber(
                            verificationCompleted:
                                (PhoneAuthCredential credential) async {},
                            verificationFailed: (FirebaseAuthException ex) {
                              print(ex);
                              Utilities.showSnackBar("${ex}", Colors.red);
                            },
                            codeSent: (String verificationId,
                                int? resendToken) async {
                              context.go(
                                '/mfa/phone/${verificationId}',
                              );
                            },
                            codeAutoRetrievalTimeout:
                                (String verificationId) {},
                            phoneNumber:
                                FirebaseAuth.instance.currentUser!.phoneNumber,
                          );
                          // context.go('/mfa/phone/123');
                        } catch (err) {
                          Utilities.showSnackBar("${err}", Colors.red);
                        }
                      },
                      child: Text(
                        "Continue",
                        style: TextStyle(
                            color: accentColor, fontWeight: FontWeight.w700),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: 32,
              ),
              InputButton(
                label: "Go back",
                function: () {
                  FirebaseAuth.instance.signOut();
                  context.go('/login');
                },
                large: true,
              ),
              SizedBox(
                height: 16,
              ),
              Text(
                "You can disable this feature in the update profile section inside the app.",
                style: CustomTextStyle.regular_minor,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
