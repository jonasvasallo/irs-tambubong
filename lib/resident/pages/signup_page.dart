import 'dart:async';
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
        await ImagePicker().pickImage(source: ImageSource.camera);
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

  String _dropdownValue = "";
  late StreamController<List<Map<String, dynamic>>> _streetsStreamController;
  late List<Map<String, dynamic>> _streets;
  Stream<List<Map<String, dynamic>>> get streetsStream =>
      _streetsStreamController.stream;

  Future<List<Map<String, dynamic>>> getStreets() async {
    List<Map<String, dynamic>> streets = [];

    try {
      QuerySnapshot tagsSnapshot =
          await FirebaseFirestore.instance.collection('streets').get();

      if (tagsSnapshot.docs.isNotEmpty) {
        for (var tagDocument in tagsSnapshot.docs) {
          Map<String, dynamic> tagData =
              tagDocument.data() as Map<String, dynamic>;
          streets.add({
            'street_id': tagDocument.id,
            'street_name': tagData['name'],
            // Add more fields if needed
          });
        }
      } else {
        print('No tags found in the incident_tags collection.');
      }
    } catch (ex) {
      print('Error fetching incident tags: $ex');
    }

    return streets;
  }

  Future signUp() async {
    if (selectedImage == null) {
      Utilities.showSnackBar("Please upload your ID first", Colors.red);
      return;
    }
    if (_dropdownValue.isEmpty) {
      Utilities.showSnackBar("You must select the street first", Colors.red);
      return;
    }

    final isValid = formKey.currentState!.validate();
    if (!isValid) {
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
      /* Handles case where given phone number is already in the system */
      bool phoneNumberExists =
          await checkPhoneNumberExists(_contactNoController.text.trim());
      var photoUrl = await uploadImageToFirebase();

      if (phoneNumberExists) {
        Utilities.showSnackBar(
          'This phone number is already associated with another account',
          Colors.red,
        );
        Navigator.of(dialogContext).pop(); // Dismiss loading indicator
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
        _firstNameController.text,
        _middleNameController.text.trim(),
        _lastNameController.text.trim(),
        currentOption,
        _birthdayController.text.trim(),
        _addressHouseController.text.trim(),
        _dropdownValue.trim(),
        _contactNoController.text.trim(),
        _emailAddressController.text.trim(),
        photoUrl,
      );

      await FirebaseAuth.instance.verifyPhoneNumber(
        verificationCompleted: (PhoneAuthCredential credential) async {},
        verificationFailed: (FirebaseAuthException ex) {
          print(ex);
          Utilities.showSnackBar("Phone verification failed: ${ex}", Colors.red);
          context.go('/login');
          return;
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
        Utilities.showSnackBar("Unexpected error has occured ${e}", Colors.red);
      }
      print('Sign Up failed ${e.message}');
    } catch (err) {
      Utilities.showSnackBar("Unexpected error has occured ${err}", Colors.red);
      print('Sign Up failed ${err}');
    }
    Navigator.of(dialogContext).pop();
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
      'profile_path':
          "https://firebasestorage.googleapis.com/v0/b/irs-capstone.appspot.com/o/default_profile.png?alt=media&token=10c91862-f50a-416c-adce-001a51b64985",
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
  void initState() {
    // TODO: implement initState
    super.initState();
    _streetsStreamController = StreamController<List<Map<String, dynamic>>>();
    _streets = [];

    // Fetch incident tags when the widget is initialized
    getStreets().then((tags) {
      _streetsStreamController.add(tags);
    });
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
                          inputType: "name",
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
                          inputType: "name",
                          label: "Middle Name",
                          controller: _middleNameController,
                        ),
                      ),
                    ],
                  ),
                  InputField(
                    placeholder: "e.g. Bello",
                    inputType: "name",
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
                  InputField(
                    inputType: "number",
                    placeholder: "e.g. 1084",
                    label: "House/Unit No.",
                    controller: _addressHouseController,
                    validator: requiredValidator,
                  ),
                  StreamBuilder(
                    stream: streetsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Data is still loading
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        // Error occurred while fetching data
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        // No data available
                        return Text('No incident tags found.');
                      } else {
                        // Data has been successfully fetched
                        final _incidentTags = snapshot.data!;

                        return DropdownMenu(
                          hintText: "Street Address",
                          width: MediaQuery.of(context).size.width - 32,
                          onSelected: (value) {
                            _dropdownValue = value!;
                          },
                          dropdownMenuEntries:
                              _incidentTags.map((Map<String, dynamic> tag) {
                            return DropdownMenuEntry(
                                value: "${tag['street_name']} Street",
                                label: "${tag['street_name']} Street");
                          }).toList(),
                        );
                      }
                    },
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
                    placeholder: "e.g. +639XXXXXXXXX",
                    inputType: "phone",
                    label: "Contact No.",
                    controller: _contactNoController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Phone number is required';
                      }

                      // Define the regex pattern for the desired format: +63 9XX-XXX-XXXX
                      RegExp regex = RegExp(r'^\+639\d{2}\d{3}\d{4}$');

                      if (!regex.hasMatch(value)) {
                        return 'Enter a valid phone number (+639XXXXXXXXX)';
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
                    placeholder: "Min. 12 characters",
                    inputType: "password",
                    label: "Password",
                    controller: _passwordController,
                    validator: InputValidator.passwordValidator,
                  ),
                  InputField(
                    placeholder: "Min. 12 characters",
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                            "By creating your account, you agree to Tambubong IRS's Terms of Service."),
                      ),
                      TextButton(
                          onPressed: () {
                            context.go('/signup/tos');
                          },
                          child: Text("Terms of Service")),
                    ],
                  ),
                  SizedBox(height: 8),
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
