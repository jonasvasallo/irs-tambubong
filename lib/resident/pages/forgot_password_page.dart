import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/widgets/input_button.dart';
import 'package:irs_app/widgets/input_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final formkey = GlobalKey<FormState>();
  final _emailAddressController = TextEditingController();

  Future passwordReset() async {
    Utilities.showLoadingIndicator(context);
    final isValid = formkey.currentState!.validate();
    if (!isValid) {
      Navigator.of(context).pop();
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailAddressController.text.trim(),
      );
      Utilities.showSnackBar(
        "Password Reset Link successfully sent",
        Colors.green,
      );
    } on FirebaseAuthException catch (ex) {
      print(ex.code);
      if (ex.code == 'user-not-found') {
        Utilities.showSnackBar(
          "This email address isn't registered in our system",
          Colors.red,
        );
      } else {
        Utilities.showSnackBar("Unexpected Error has occured", Colors.red);
      }
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _emailAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Forgot Password"),
        leading: TextButton(
          child: Icon(Icons.chevron_left),
          onPressed: () {
            context.go('/login');
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Form(
            key: formkey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Enter your email address and we will send you a password reset link.",
                  style: TextStyle(
                      color: majorText,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
                InputField(
                  placeholder: "Email Address",
                  inputType: "email",
                  controller: _emailAddressController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    } else if (!EmailValidator.validate(value)) {
                      return 'Enter a valid email address';
                    }
                    return null; // Return null if validation succeeds
                  },
                ),
                InputButton(
                  label: "Send Link",
                  function: () {
                    passwordReset();
                  },
                  large: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
