import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/input_validator.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/widgets/input_button.dart';
import 'package:irs_app/widgets/input_field.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

List<String> sex_options = ["Male", "Female"];

class _SignupPageState extends State<SignupPage> {
  /* Text Controllers */
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _genderController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _addressHouseController = TextEditingController();
  final _addressStreetController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _emailAddressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  File? selectedImage;

  Image imageShown = Image.network(
    "https://i.pinimg.com/originals/2e/60/07/2e60079f1e36b5c7681f0996a79e8af4.jpg",
    fit: BoxFit.contain,
  );

  Future _pickImageFromGallery() async {
    final returnedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnedImage == null) return;
    setState(() {
      selectedImage = File(returnedImage!.path);
      imageShown = Image.file(
        selectedImage!,
        fit: BoxFit.cover,
      );
    });
  }

  Future<String> uploadImageToFirebase() async {
    try {
      if (selectedImage != null) {
        final path =
            'user_verifications/${selectedImage!.path.split('/').last}';

        final ref = FirebaseStorage.instance.ref().child(path);
        UploadTask? uploadTask = ref.putFile(selectedImage!);

        final snapshot = await uploadTask!.whenComplete(() => null);

        var urlDownload = await snapshot.ref.getDownloadURL();
        return urlDownload;
      }
      print("selectedImage is null");
      return '';
    } catch (ex) {
      Utilities.showSnackBar(
          "Error uploading file to firebase $ex", Colors.red);
    }
    return '';
  }

  final String? Function(String?)? requiredValidator = (value) =>
      (value != null && value.length <= 0) ? 'This field is required' : null;

  String currentOption = sex_options[0];

  Future<bool> checkPhoneNumberExists(String phoneNumber) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('contact_no', isEqualTo: phoneNumber)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Future signUp() async {
    if (selectedImage == null) {
      Utilities.showSnackBar("Please upload your ID first", Colors.red);
      return;
    }
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
      var photoUrl = await uploadImageToFirebase();

      // if (phoneNumberExists) {
      //   Utilities.showSnackBar(
      //     'This phone number is already associated with another account',
      //     Colors.red,
      //   );
      //   Navigator.of(context).pop(); // Dismiss loading indicator
      //   return;
      // }
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
        currentOption,
        _birthdayController.text.trim(),
        _addressHouseController.text.trim(),
        _addressStreetController.text.trim(),
        _contactNoController.text.trim(),
        _emailAddressController.text.trim(),
        photoUrl,
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
    String gender,
    String birthday,
    String addressHouse,
    String addressStreet,
    String contactNo,
    String emailAddress,
    String verification_photo,
  ) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'gender': gender,
      'birthday': birthday,
      'address_house': addressHouse,
      'address_street': addressStreet,
      'contact_no': contactNo,
      'email': emailAddress,
      'deactivation': false,
      'lastLogin': FieldValue.serverTimestamp(),
      'user_type': 'resident',
      'verified': false,
      'sms_verified': false,
      'profile_path': "https://i.stack.imgur.com/l60Hf.png",
      'verification_photo': verification_photo,
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _genderController.dispose();
    _birthdayController.dispose();
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Sex",
                            style: CustomTextStyle.regular,
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.all(4),
                            title: const Text("Male"),
                            leading: Radio(
                              value: sex_options[0],
                              groupValue: currentOption,
                              onChanged: (value) {
                                setState(() {
                                  currentOption = value.toString();
                                });
                              },
                            ),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.all(4),
                            title: const Text("Female"),
                            leading: Radio(
                              value: sex_options[1],
                              groupValue: currentOption,
                              onChanged: (value) {
                                setState(() {
                                  currentOption = value.toString();
                                });
                              },
                            ),
                          )
                        ],
                      )),
                      SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child: InputField(
                          inputType: "date",
                          placeholder: "Birth Day",
                          label: "Birthday",
                          controller: _birthdayController,
                          validator: InputValidator.requiredValidator,
                        ),
                      ),
                    ],
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
                  Text(
                    "In order to verify you are a legitimate resident, please upload a photo of any ID that matches the address you have provided",
                    style: CustomTextStyle.regular_minor,
                  ),
                  OutlinedButton(
                    onPressed: () {
                      _pickImageFromGallery();
                    },
                    child: IntrinsicWidth(
                      child: Row(
                        children: [
                          Icon(Icons.add),
                          Text("Attach Photo"),
                        ],
                      ),
                    ),
                    style: ButtonStyle(
                      padding: MaterialStatePropertyAll(
                        EdgeInsets.only(
                          top: 8,
                          bottom: 8,
                          left: 16,
                          right: 16,
                        ),
                      ),
                      side: MaterialStatePropertyAll(
                        BorderSide(color: accentColor, width: 1),
                      ),
                    ),
                  ),
                  (selectedImage != null)
                      ? Container(
                          width: 393,
                          height: 150,
                          child: Image.file(
                            selectedImage!,
                            fit: BoxFit.contain,
                          ),
                        )
                      : SizedBox(),
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
