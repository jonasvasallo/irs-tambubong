import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_capstone/constants.dart';
import 'package:irs_capstone/utilities.dart';
import 'package:irs_capstone/widgets/input_button.dart';
import 'package:irs_capstone/widgets/input_field.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  /* Text Controllers */
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressHouseController = TextEditingController();
  final _addressStreetController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _emailAddressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  final String? Function(String?)? requiredValidator = (value) =>
      (value != null && value.length <= 0) ? 'This field is required' : null;

  Future<bool> checkPhoneNumberExists(String phoneNumber) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('contact_no', isEqualTo: phoneNumber)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Future signUp() async {
    Utilities.showLoadingIndicator(context);
    final isValid = formKey.currentState!.validate();
    if (!isValid) {
      Navigator.of(context).pop();
      return;
    }
    try {
      /* Handles case where given phone number is already in the system */
      bool phoneNumberExists =
          await checkPhoneNumberExists(_contactNoController.text.trim());

      if (phoneNumberExists) {
        Utilities.showSnackBar(
          'This phone number is already associated with another account',
          Colors.red,
        );
        Navigator.of(context).pop(); // Dismiss loading indicator
        return;
      }
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailAddressController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String userId = userCredential.user?.uid ?? '';

      addUserDetails(
        userId,
        _firstNameController.text.trim(),
        _middleNameController.text.trim(),
        _lastNameController.text.trim(),
        _addressHouseController.text.trim(),
        _addressStreetController.text.trim(),
        _contactNoController.text.trim(),
        _emailAddressController.text.trim(),
      );

      await FirebaseAuth.instance.verifyPhoneNumber(
        verificationCompleted: (PhoneAuthCredential credential) async {},
        verificationFailed: (FirebaseAuthException ex) {
          print(ex);
        },
        codeSent: (String verificationId, int? resendToken) async {
          context.go(
            '/verify/${verificationId}/${_contactNoController.text.trim()}',
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        phoneNumber: _contactNoController.text.toString(),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        Utilities.showSnackBar(
          'This email is already associated with another account',
          Colors.red,
        );
      } else {
        Utilities.showSnackBar("Unexpected error has occured", Colors.red);
      }
      print('Sign Up failed ${e.message}');
    }
    Navigator.of(context).pop();
  }

  Future addUserDetails(
      String userId,
      String firstName,
      String middleName,
      String lastName,
      String addressHouse,
      String addressStreet,
      String contactNo,
      String emailAddress) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'address_house': addressHouse,
      'address_street': addressStreet,
      'contact_no': contactNo,
      'email': emailAddress,
      'verified': false,
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _addressHouseController.dispose();
    _addressStreetController.dispose();
    _contactNoController.dispose();
    _emailAddressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: padding16,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Create an account",
                    style: CustomTextStyle.heading,
                  ),
                  Text(
                    "Be notified about the incidents around your area",
                    style: CustomTextStyle.regular_minor,
                  ),
                  SizedBox(
                    height: 24,
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: InputField(
                          placeholder: "e.g. Saimon",
                          inputType: "text",
                          label: "First Name",
                          controller: _firstNameController,
                          validator: requiredValidator,
                        ),
                      ),
                      SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        flex: 1,
                        child: InputField(
                          placeholder: "e.g. Bautista",
                          inputType: "text",
                          label: "Middle Name",
                          controller: _middleNameController,
                          validator: requiredValidator,
                        ),
                      ),
                    ],
                  ),
                  InputField(
                    placeholder: "e.g. Bello",
                    inputType: "text",
                    label: "Last Name",
                    controller: _lastNameController,
                    validator: requiredValidator,
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: InputField(
                          inputType: "text",
                          placeholder: "e.g. 1084",
                          label: "House/Unit No.",
                          controller: _addressHouseController,
                          validator: requiredValidator,
                        ),
                      ),
                      SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child: InputField(
                          inputType: "text",
                          placeholder: "e.g. Kalsadang Bago",
                          label: "Street",
                          controller: _addressStreetController,
                          validator: requiredValidator,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  InputField(
                    placeholder: "e.g. +63 9XX-XXX-XXXX",
                    inputType: "number",
                    label: "Contact No.",
                    controller: _contactNoController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Phone number is required';
                      }

                      // Define the regex pattern for the desired format: +63 9XX-XXX-XXXX
                      RegExp regex = RegExp(r'^\+63 9\d{2}-\d{3}-\d{4}$');

                      if (!regex.hasMatch(value)) {
                        return 'Enter a valid phone number (+63 9XX-XXX-XXXX)';
                      }

                      return null; // Return null if validation succeeds
                    },
                  ),
                  InputField(
                    placeholder: "e.g. saimonbello@gmail.com",
                    inputType: "email",
                    label: "Email Address",
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
                  InputField(
                    placeholder: "Min. 8 characters",
                    inputType: "password",
                    label: "Password",
                    controller: _passwordController,
                    validator: (value) => value != null && value.length < 8
                        ? 'Enter min. 8 characters'
                        : null,
                  ),
                  InputField(
                    placeholder: "Min. 8 characters",
                    inputType: "password",
                    label: "Confirm Password",
                    controller: _confirmPasswordController,
                    validator: (value) => value != null &&
                            value != _passwordController.text.trim()
                        ? 'Both passwords must match'
                        : null,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  InputButton(
                    label: "Create Account",
                    function: () {
                      signUp();
                    },
                    large: true,
                  ),
                  SizedBox(
                    height: 24,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account?",
                        style: CustomTextStyle.regular_minor,
                      ),
                      TextButton(
                        onPressed: () {
                          context.go('/login');
                        },
                        child: Text(
                          "Login here.",
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
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
