import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_capstone/core/input_validator.dart';
import 'package:irs_capstone/core/utilities.dart';
import 'package:irs_capstone/models/user_model.dart';
import 'package:irs_capstone/widgets/input_button.dart';
import 'package:irs_capstone/widgets/input_field.dart';

class VerifyChangePage extends StatefulWidget {
  final String type;
  final String? email;
  final String? phoneNumber;
  const VerifyChangePage({
    Key? key,
    required this.type,
    this.email,
    this.phoneNumber,
  }) : super(key: key);

  @override
  State<VerifyChangePage> createState() => _VerifyChangePageState();
}

class _VerifyChangePageState extends State<VerifyChangePage> {
  final _newEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _smsController = TextEditingController();
  final _phoneNoController = TextEditingController();
  String _verificationId = "";

  final formKey = GlobalKey<FormState>();
  final phoneNoKey = GlobalKey<FormState>();
  void changeEmail() async {
    InputValidator.checkFormValidity(formKey, context);
    try {
      UserModel model = new UserModel();
      await model.changeEmail(
        widget.email ?? '',
        _passwordController.text.trim(),
        _newEmailController.text.trim(),
      );
      Utilities.showSnackBar("Successfully Updated Email", Colors.green);
      context.go('/profile/true');
    } on FirebaseAuthException catch (ex) {
      print(ex);
      Utilities.showSnackBar("${ex.message}", Colors.red);
    }
  }

  void changePhone() async {
    try {
      InputValidator.checkFormValidity(formKey, context);
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

          context.go('/profile/true');
        }
      } else {
        // Handle case where verification ID or SMS code is missing
        print("Verification ID or SMS code is missing");
      }
    } on FirebaseAuthException catch (ex) {
      print(ex);
      Utilities.showSnackBar("${ex.message}", Colors.red);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _newEmailController.dispose();
    _smsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(Icons.chevron_left),
        ),
      ),
      body: Form(
        key: formKey,
        child: SafeArea(
          child: (widget.type == 'email')
              ? Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      InputField(
                        placeholder: "Email Address",
                        inputType: 'email',
                        controller: _newEmailController,
                        label: "New Email Address",
                      ),
                      Text("Enter your password to change your email"),
                      InputField(
                        placeholder: "Password",
                        inputType: 'password',
                        controller: _passwordController,
                        label: "Password",
                      ),
                      InputButton(
                        label: "Change Email",
                        function: () {
                          changeEmail();
                        },
                        large: false,
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
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
                                    verificationCompleted: (PhoneAuthCredential
                                        credential) async {},
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
                        ],
                      ),
                      InputField(
                        placeholder: "6 digit SMS",
                        inputType: "text",
                        controller: _smsController,
                        validator: (value) =>
                            (value != null && value.length < 6)
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
    );
  }
}
