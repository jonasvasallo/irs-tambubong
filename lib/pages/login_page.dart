import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_capstone/constants.dart';
import 'package:irs_capstone/core/input_validator.dart';
import 'package:irs_capstone/core/utilities.dart';
import 'package:irs_capstone/models/user_model.dart';
import 'package:irs_capstone/widgets/input_field.dart';
import 'dart:async';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  StreamSubscription<User?>? _authSubscription;

  Future<void> signIn() async {
    Utilities.showLoadingIndicator(context);
    final isValid = formKey.currentState!.validate();
    if (!isValid) {
      Navigator.of(context).pop();
      return;
    }
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      UserModel model = new UserModel();

      await UserModel.getUserById(model.uId);

      if (await model.deleteInactiveUser(model.uId)) {
        Utilities.showSnackBar(
          "Your account was deactivated. Please register a new one.",
          Colors.red,
        );
        return;
      } else {}

      // Sign-in was successful, now listen for authentication state changes
      _authSubscription =
          FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        if (user == null) {
          // User is signed out
          print('User is signed out');
        } else {
          await model.loginTimestamp(model.uId);
          // User is signed in
          print('User is signed in');
          print('User UID: ${user.uid}');

          context.go('/home');
          // Here, you can proceed with actions to be taken after successful sign-in
        }
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'INVALID_LOGIN_CREDENTIALS') {
        Utilities.showSnackBar('Invalid Login Credentials', Colors.red);
      } else if (e.code == 'too-many-requests') {
        Utilities.showSnackBar(
            'Too many login attempts. Try again later.', Colors.red);
      } else if (e.code == 'user-not-found') {
        Utilities.showSnackBar(
            'No user has been found with this credentials', Colors.red);
      } else {
        Utilities.showSnackBar('Unexpected Error has occured', Colors.red);
      }
      // Handle sign-in errors
      print('Sign-in failed: $e');
      // You can display an error message or handle the error in another way
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              child: Text("test"),
              decoration: BoxDecoration(
                color: Colors.grey,
              ),
              height: 278,
              width: double.infinity,
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Connect and Be Aware",
                      style: TextStyle(
                        fontSize: 24,
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 49,
                    ),
                    Text(
                      "Sign in to your account",
                      style: TextStyle(
                        color: majorText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    InputField(
                      placeholder: "Email Address",
                      inputType: "email",
                      controller: _emailController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        } else if (!EmailValidator.validate(value)) {
                          return 'Enter a valid email address';
                        }
                        return null; // Return null if validation succeeds
                      },
                    ),
                    InputField(
                      placeholder: "Password",
                      inputType: "password",
                      controller: _passwordController,
                      validator: InputValidator.requiredValidator,
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        "Forgot password?",
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          decorationColor: accentColor,
                          color: accentColor,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    FilledButton(
                      style: ButtonStyle(
                        padding: MaterialStatePropertyAll(
                          EdgeInsets.all(16),
                        ),
                        minimumSize: MaterialStatePropertyAll(
                          Size.fromHeight(43),
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      onPressed: signIn,
                      child: Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 40,
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "No account yet?",
                  style: CustomTextStyle.regular,
                ),
                TextButton(
                  onPressed: () {
                    // GoRouter.of(context).go('/signup');
                    context.go('/signup');
                  },
                  child: Text(
                    "Create an Account",
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      decorationColor: accentColor,
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.normal,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
