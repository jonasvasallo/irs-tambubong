import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/input_validator.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/models/user_model.dart';
import 'package:irs_app/widgets/input_button.dart';
import 'package:irs_app/widgets/input_field.dart';

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({Key? key}) : super(key: key);

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

List<String> sex_options = ["Male", "Female"];

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  UserModel model = new UserModel();
  final formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _genderController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _addressHouseController = TextEditingController();
  final _addressStreetController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _emailAddressController = TextEditingController();
  String profile_path =
      "https://firebasestorage.googleapis.com/v0/b/irs-capstone.appspot.com/o/default_profile.png?alt=media&token=10c91862-f50a-416c-adce-001a51b64985";
  String verification_id = "";
  Timestamp? lastUpdate;

  bool verified = false;

  bool mfaEnabled = false;

  File? selectedImage;

  Image imageShown = Image.network(
    "https://i.stack.imgur.com/l60Hf.png",
    fit: BoxFit.cover,
  );

  String currentOption = sex_options[0];

  Future _pickImageFromGallery() async {
    final returnedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnedImage == null) return;

    setState(() {
      selectedImage = File(returnedImage.path);
      imageShown = Image.file(
        selectedImage!,
        fit: BoxFit.cover,
      );
    });
  }

  Future _uploadID() async {
    final returnedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnedImage == null) return;

    final image = File(returnedImage.path);

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
      var urlDownload = "";

      if (image != null) {
        final path = '/user/verifications/${image!.path.split('/').last}';

        final ref = FirebaseStorage.instance.ref().child(path);
        UploadTask? uploadTask = ref.putFile(image!);

        final snapshot = await uploadTask!.whenComplete(() => null);

        urlDownload = await snapshot.ref.getDownloadURL();
      }

      if (urlDownload.isEmpty) {
        Utilities.showSnackBar("Download URL is empty!", Colors.red);
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        'verification_photo': urlDownload,
      });

      Utilities.showSnackBar(
          "Successfully upload verification ID", Colors.green);
      setState(() {
        verification_id = urlDownload;
      });
    } catch (error) {
      print(error);
      Utilities.showSnackBar("${error.toString()}", Colors.red);
    }
    Navigator.pop(dialogContext);
  }

  void fetchDetails() async {
    Map<String, dynamic>? userDetails = await UserModel.getUserById(model.uId);
    if (userDetails != null) {
      // Update text controllers with user details
      setState(() {
        _firstNameController.text = userDetails['first_name'] ?? '';
        _middleNameController.text = userDetails['middle_name'] ?? '';
        _lastNameController.text = userDetails['last_name'] ?? '';
        _genderController.text = userDetails['gender'] ?? '';
        currentOption = userDetails['gender'] ?? '';
        _birthdayController.text = userDetails['birthday'] ?? '';
        _addressHouseController.text = userDetails['address_house'] ?? '';
        _dropdownValue = userDetails['address_street'] ?? '';
        _contactNoController.text = userDetails['contact_no'] ?? '';
        _emailAddressController.text = userDetails['email'] ?? '';
        profile_path = userDetails['profile_path'] ??
            'https://i.stack.imgur.com/l60Hf.png';
        imageShown = Image.network(
          profile_path,
          fit: BoxFit.cover,
        );
        verification_id = userDetails['verification_photo'] ?? '';
        verified = userDetails['verified'] ?? false;
        lastUpdate = (userDetails['lastUpdated'] != null)
            ? userDetails['lastUpdated'] as Timestamp
            : null;
        mfaEnabled = (userDetails['mfa_enabled'] != null)
            ? userDetails['mfa_enabled']
            : false;
      });
    } else {
      print('User details not found');
    }
  }

  bool checkIfSixMonthsPassed(Timestamp lastUpdateTimestamp) {
    Timestamp currentTimestamp = Timestamp.now();

    int difference = currentTimestamp.millisecondsSinceEpoch -
        lastUpdateTimestamp.millisecondsSinceEpoch;

    double monthsDifference = difference / (1000 * 60 * 60 * 24 * 30.44);

    return monthsDifference >= 6;
  }

  void updateDetails() async {
    if (_dropdownValue.isEmpty) {
      Utilities.showSnackBar("You must select the street first", Colors.red);
      return;
    }
    if (lastUpdate != null && !checkIfSixMonthsPassed(lastUpdate!)) {
      Utilities.showSnackBar(
          "You can only update your profile every six months for security purposes. Submit a ticket if you think this is a problem.",
          Colors.red);
      return;
    }
    InputValidator.checkFormValidity(formKey, context);
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
      var urlDownload = profile_path;

      if (selectedImage != null) {
        final path = '/user/profile_pic/${selectedImage!.path.split('/').last}';

        final ref = FirebaseStorage.instance.ref().child(path);
        UploadTask? uploadTask = ref.putFile(selectedImage!);

        final snapshot = await uploadTask!.whenComplete(() => null);

        urlDownload = await snapshot.ref.getDownloadURL();
      }

      await model.updateUserDetails(
        model.uId,
        _firstNameController.text.trim(),
        _middleNameController.text.trim(),
        _lastNameController.text.trim(),
        currentOption,
        _birthdayController.text.trim(),
        _addressHouseController.text.trim(),
        _dropdownValue.trim(),
        urlDownload,
      );

      Utilities.showSnackBar("Successfully Updated Details", Colors.green);
    } catch (ex) {
      Utilities.showSnackBar("$ex", Colors.red);
    } finally {
      Navigator.pop(dialogContext);
      context.go('/profile/true');
    }
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchDetails();
    _streetsStreamController = StreamController<List<Map<String, dynamic>>>();
    _streets = [];

    // Fetch incident tags when the widget is initialized
    getStreets().then((tags) {
      _streetsStreamController.add(tags);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Personal Information"),
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(
            Icons.chevron_left,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(150),
                        child: imageShown,
                      ),
                    ),
                    Center(
                      child: IconButton(
                        onPressed: () {
                          print("open picture");
                          _pickImageFromGallery();
                        },
                        icon: Icon(
                          Icons.photo,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
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
                        validator: InputValidator.requiredValidator,
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
                  validator: InputValidator.requiredValidator,
                ),
                Row(
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
                  validator: InputValidator.requiredValidator,
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
                      return Text('No street found.');
                    } else {
                      // Data has been successfully fetched
                      final _incidentTags = snapshot.data!;

                      return DropdownMenu(
                        initialSelection: _dropdownValue,
                        label: Text(_dropdownValue),
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
                (verification_id.isNotEmpty)
                    ? Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              (verified)
                                  ? "Verification ID (Verified)"
                                  : "Verification ID (Pending verification)",
                              style: CustomTextStyle.subheading,
                            ),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width - 32,
                            height: 150,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                verification_id,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Text(
                            "Upload an ID to verify your account",
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          TextButton(
                            onPressed: () {
                              _uploadID();
                            },
                            child: Text("Upload ID"),
                          ),
                        ],
                      ),
                SizedBox(
                  height: 16,
                ),
                Row(
                  children: [
                    Text(_contactNoController.text.trim()),
                    TextButton(
                      onPressed: () {
                        context.go('/profile/update/phone');
                      },
                      child: Text("Change"),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(_emailAddressController.text.trim()),
                    TextButton(
                      onPressed: () {
                        context.go(
                            '/profile/update/email/${_emailAddressController.text}');
                      },
                      child: Text("Change"),
                    ),
                  ],
                ),
                SizedBox(
                  height: 8,
                ),
                Row(
                  children: [
                    Text("Two-factor Authentication"),
                    SizedBox(
                      width: 8,
                    ),
                    Switch(
                      trackOutlineColor:
                          WidgetStatePropertyAll(Colors.transparent),
                      activeColor: Colors.green,
                      activeTrackColor: Colors.greenAccent,
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Color.fromARGB(255, 242, 243, 245),
                      value: mfaEnabled,
                      onChanged: (value) async {
                        setState(() {
                          mfaEnabled = !mfaEnabled;
                        });
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .update({
                          'mfa_enabled': mfaEnabled,
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(
                  height: 8,
                ),
                InputButton(
                  label: "Update Profile",
                  function: () {
                    updateDetails();
                  },
                  large: false,
                ),
                SizedBox(
                  height: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
