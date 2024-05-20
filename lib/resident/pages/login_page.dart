import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_app/app_router.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/input_validator.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/models/user_model.dart';
import 'package:irs_app/widgets/input_field.dart';
import 'dart:async';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isMounted = false;
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

      Map<String, dynamic>? details = await UserModel.getUserById(model.uId);
      print(details);
      if (details != null) {
        var disabled = details['disabled'] ?? false;
        if (disabled) {
          Utilities.showSnackBar("Your account has been disabled", Colors.red);
          Navigator.of(context).pop();
          FirebaseAuth.instance.signOut();
          return;
        }
        if (details['sms_verified'] == false) {
          await FirebaseAuth.instance.verifyPhoneNumber(
            verificationCompleted: (PhoneAuthCredential credential) async {},
            verificationFailed: (FirebaseAuthException ex) {
              print(ex);
            },
            codeSent: (String verificationId, int? resendToken) async {
              context.go(
                '/verify/${verificationId}/${details['contact_no']}',
              );
              return;
            },
            codeAutoRetrievalTimeout: (String verificationId) {},
            phoneNumber: details['contact_no'],
          );
        } else {
          if (await model.deleteInactiveUser(model.uId)) {
            Utilities.showSnackBar(
              "Your account was deactivated. Please register a new one.",
              Colors.red,
            );
            return;
          } else {}

          // Sign-in was successful, now listen for authentication state changes
          _authSubscription = FirebaseAuth.instance
              .authStateChanges()
              .listen((User? user) async {
            if (user == null) {
              // User is signed out
              print('User is signed out');
            } else {
              await model.loginTimestamp(model.uId);
              print("working 1");
              DocumentSnapshot documentSnapshot = await FirebaseFirestore
                  .instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .get();
              print("working 2");
              if (documentSnapshot.exists) {
                Map<String, dynamic> userDetails =
                    documentSnapshot.data() as Map<String, dynamic>;
                print("working 3");

                if (_isMounted) {
                  print("working 4");
                  if (userDetails['user_type'] == 'resident') {
                    print("working 5");
                    AppRouter.initR = "/home";
                    context.go('/home');
                  } else {
                    AppRouter.initR = "/tanod_home";
                    context.go('/tanod_home');
                  }
                }
              } else {
                Utilities.showSnackBar("User not in collection", Colors.red);
              }
            }
          });
        }
      }
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
        Utilities.showSnackBar('${e.message}', Colors.red);
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
    _isMounted = false;
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _isMounted = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              child: Image.asset(
                "assets/map.png",
                fit: BoxFit.cover,
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
                      height: 24,
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
                      onPressed: () {
                        context.go('/forgot-password');
                      },
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
                      height: 24,
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
