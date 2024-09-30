import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_app/app_router.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/input_validator.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/models/firebase_api.dart';
import 'package:irs_app/models/user_model.dart';
import 'package:irs_app/widgets/input_field.dart';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

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

  static const int maxAttempts = 3;
  static const int twoMinutes = 2 * 60 * 1000;
  static const String lastAttemptKey = 'lastAttempt';
  static const String attemptCountKey = "attemptCount";

  Future<void> checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Get last login attempt and failed attempt count
    final int? lastAttempt = prefs.getInt(lastAttemptKey);
    final int attemptCount = prefs.getInt(attemptCountKey) ?? 0;

    print("${attemptCount}, ${lastAttempt ?? 123}");

    // If the user has failed 3 attempts and hasn't waited 2 minutes
    if (attemptCount >= maxAttempts - 1 && lastAttempt != null) {
      print("is this happening");
      final int now = DateTime.now().millisecondsSinceEpoch;
      final int difference = now - lastAttempt;

      if (difference < twoMinutes) {
        Utilities.showSnackBar(
          "You have to wait 2 minutes before trying again",
          Colors.red,
        );
        return;
      } else {
        // Reset attempts after 2 minutes have passed
        await prefs.remove(lastAttemptKey);
        await prefs.remove(attemptCountKey);
      }
    }

    await signIn();
  }

  Future<void> signIn() async {
    Utilities.showLoadingIndicator(context);
    final isValid = formKey.currentState!.validate();
    if (!isValid) {
      Navigator.of(context).pop();
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      prefs.remove(attemptCountKey);

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
              Utilities.showSnackBar(
                  "Phone verification failed: ${ex}", Colors.red);
              context.go('/home');
              return;
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
          if (details['passwordLastUpdated'] == null ||
              DateTime.now()
                      .difference((details['passwordLastUpdated'] as Timestamp)
                          .toDate())
                      .inDays >=
                  30) {
            // Notify user to update their password
            Utilities.showSnackBar(
              "Your password is older than 30 days. Please update it.",
              Colors.red,
            );
            Navigator.of(context).pop();
            context.go('/password-expired');
            return;
          }

          //MFA Functionality

          if (details['mfa_enabled'] != null &&
              details['mfa_enabled'] == true) {
            Navigator.of(context).pop();
            context.go('/mfa');
            return;
          }

          // Sign-in was successful, now listen for authentication state changes
          _authSubscription = FirebaseAuth.instance
              .authStateChanges()
              .listen((User? user) async {
            if (user == null) {
              // User is signed out
              print('User is signed out');
            } else {
              await model.loginTimestamp(model.uId);
              await model.updateFCMToken(
                  model.uId, await FirebaseApi().initNotifications() ?? '');
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
                  } else if (userDetails['user_type'] == 'admin' ||
                      userDetails['user_type'] == 'moderator') {
                    AppRouter.initR = "/admin_home";
                    context.go('/admin_home');
                  } else if (userDetails['user_type'] == 'tanod') {
                    AppRouter.initR = "/tanod_home";
                    context.go('/tanod_home');
                  } else {
                    FirebaseAuth.instance.signOut();
                    Utilities.showSnackBar(
                        "Unknown user type. Contact the admin if you think this is a problem. ",
                        Colors.red);
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
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        // Increment failed attempt count
        int attemptCount = prefs.getInt(attemptCountKey) ?? 0;
        attemptCount += 1;

        if (attemptCount >= maxAttempts) {
          prefs.setInt(lastAttemptKey, DateTime.now().millisecondsSinceEpoch);
          Utilities.showSnackBar(
            "Too many failed attempts. Please wait two minutes.",
            Colors.red,
          );
        } else {
          prefs.setInt(attemptCountKey, attemptCount);
          Utilities.showSnackBar(
            "Invalid credentials. You have ${maxAttempts - attemptCount} attempts left.",
            Colors.red,
          );
        }
      } else {
        Utilities.showSnackBar('${e.message}', Colors.red);
      }
    } catch (err) {
      Utilities.showSnackBar('${err}', Colors.red);
      print(err);
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
                      onPressed: checkLogin,
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
