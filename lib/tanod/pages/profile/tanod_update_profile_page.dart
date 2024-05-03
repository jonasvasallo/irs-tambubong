import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:irs_capstone/constants.dart';
import 'package:irs_capstone/core/input_validator.dart';
import 'package:irs_capstone/core/utilities.dart';
import 'package:irs_capstone/models/user_model.dart';
import 'package:irs_capstone/widgets/input_button.dart';
import 'package:irs_capstone/widgets/input_field.dart';

class TanodUpdateProfilePage extends StatefulWidget {
  const TanodUpdateProfilePage({Key? key}) : super(key: key);

  @override
  State<TanodUpdateProfilePage> createState() => _TanodUpdateProfilePageState();
}

List<String> sex_options = ["Male", "Female"];

class _TanodUpdateProfilePageState extends State<TanodUpdateProfilePage> {
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
  String profile_path = "https://i.stack.imgur.com/l60Hf.png";

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
        _addressStreetController.text = userDetails['address_street'] ?? '';
        _contactNoController.text = userDetails['contact_no'] ?? '';
        _emailAddressController.text = userDetails['email'] ?? '';
        profile_path = userDetails['profile_path'] ??
            'https://i.stack.imgur.com/l60Hf.png';
        imageShown = Image.network(
          profile_path,
          fit: BoxFit.cover,
        );
      });
    } else {
      print('User details not found');
    }
  }

  void updateDetails() async {
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
        _addressStreetController.text.trim(),
        urlDownload,
      );

      Utilities.showSnackBar("Successfully Updated Details", Colors.green);
    } catch (ex) {
      Utilities.showSnackBar("$ex", Colors.red);
    } finally {
      Navigator.pop(dialogContext);
      context.go('/tanod_home/profile');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchDetails();
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
                        inputType: "text",
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
                Row(
                  children: [
                    Expanded(
                      child: InputField(
                        inputType: "text",
                        placeholder: "e.g. 1084",
                        label: "House/Unit No.",
                        controller: _addressHouseController,
                        validator: InputValidator.requiredValidator,
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
                    Text(_contactNoController.text.trim()),
                    TextButton(
                      onPressed: () {
                        context.go('/tanod_home/profile/update/phone');
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
                            '/tanod_home/profile/update/email/${_emailAddressController.text}');
                      },
                      child: Text("Change"),
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
