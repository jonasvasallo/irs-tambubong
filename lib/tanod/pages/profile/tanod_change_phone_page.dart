import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/input_validator.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/models/user_model.dart';
import 'package:irs_app/widgets/input_button.dart';
import 'package:irs_app/widgets/input_field.dart';

class TanodChangePhonePage extends StatefulWidget {
  const TanodChangePhonePage({Key? key}) : super(key: key);

  @override
  _TanodChangePhonePageState createState() => _TanodChangePhonePageState();
}

class _TanodChangePhonePageState extends State<TanodChangePhonePage> {
  final _smsController = TextEditingController();
  final _phoneNoController = TextEditingController();
  final _passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final phoneNoKey = GlobalKey<FormState>();
  String _verificationId = "";

  void changePhone() async {
    InputValidator.checkFormValidity(formKey, context);
    if (_verificationId.isEmpty) {
      Utilities.showSnackBar("Send the SMS code first", Colors.red);
      return;
    }
    BuildContext dialogContext = context;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        dialogContext = context;
        return Center(
          child: CircularProgressIndicator(
            color: accentColor,
          ),
        );
      },
    );
    try {
      UserModel model = new UserModel();
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print("current phone number: ${user.phoneNumber}");
        // Ensure both verification ID and SMS code are available
        if (_verificationId.isNotEmpty &&
            _smsController.text.trim().isNotEmpty) {
          AuthCredential emailPasswordCredential = EmailAuthProvider.credential(
            email: user.email ?? '', // Provide the user's email
            password:
                _passwordController.text.trim(), // Provide the user's password
          );
          PhoneAuthCredential credential = PhoneAuthProvider.credential(
            verificationId: _verificationId,
            smsCode: _smsController.text.trim(),
          );

          // Reauthenticate user with credential
          await user.reauthenticateWithCredential(emailPasswordCredential);

          // Update the phone number
          await user.updatePhoneNumber(credential);

          // Update phone number in database
          await model.users.doc(model.uId).update({
            'contact_no': _phoneNoController.text.trim(),
          });
          Navigator.pop(dialogContext);
          Utilities.showSnackBar("Successfully updated phone", Colors.green);

          context.go('/tanod_home/profile');
        }
      } else {
        // Handle case where verification ID or SMS code is missing
        print("Verification ID or SMS code is missing");
      }
    } on FirebaseAuthException catch (ex) {
      Navigator.pop(dialogContext);
      print(ex);
      Utilities.showSnackBar("${ex.message}", Colors.red);
    }
  }

  @override
  void dispose() {
    _phoneNoController.dispose();
    _smsController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Change Phone Number"),
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(Icons.chevron_left),
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Form(
                        key: phoneNoKey,
                        child: Expanded(
                          child: InputField(
                            placeholder: "+63 9XX-XXX-XXXX",
                            inputType: "phone",
                            controller: _phoneNoController,
                            label: "New Phone Number",
                            validator: InputValidator.phoneValidator,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InputButton(
                            label: "SEND SMS",
                            function: () async {
                              InputValidator.checkFormValidity(
                                  phoneNoKey, context);
                              if (_phoneNoController.text.length < 16) {
                                print('phone no is less than 16 characters');
                                Utilities.showSnackBar(
                                    "Phone Number format is incorrect",
                                    Colors.red);
                                return;
                              }
                              User? user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                await FirebaseAuth.instance.verifyPhoneNumber(
                                  verificationCompleted:
                                      (PhoneAuthCredential credential) async {},
                                  verificationFailed:
                                      (FirebaseAuthException ex) {
                                    print(ex);
                                  },
                                  codeSent: (String verificationId,
                                      int? resendToken) async {
                                    setState(() {
                                      _verificationId = verificationId;
                                    });
                                    print(
                                        "ID after code sent: $_verificationId");
                                  },
                                  codeAutoRetrievalTimeout:
                                      (String verificationId) {},
                                  phoneNumber: _phoneNoController.text.trim(),
                                );
                              }
                            },
                            large: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                  InputField(
                    placeholder: "6 digit SMS",
                    inputType: "text",
                    controller: _smsController,
                    validator: (value) => (value != null && value.length < 6)
                        ? 'Code must be 6 digits'
                        : null,
                  ),
                  InputField(
                    placeholder: "Enter Password",
                    inputType: 'password',
                    controller: _passwordController,
                    validator: InputValidator.requiredValidator,
                  ),
                  InputButton(
                    label: "UPDATE PHONE NUMBER",
                    function: () {
                      InputValidator.checkFormValidity(formKey, context);
                      changePhone();
                    },
                    large: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
