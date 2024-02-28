import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_capstone/core/input_validator.dart';
import 'package:irs_capstone/core/utilities.dart';
import 'package:irs_capstone/models/user_model.dart';
import 'package:irs_capstone/widgets/input_button.dart';
import 'package:irs_capstone/widgets/input_field.dart';

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({Key? key}) : super(key: key);

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

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

  void fetchDetails() async {
    Map<String, dynamic>? userDetails = await UserModel.getUserById(model.uId);
    if (userDetails != null) {
      // Update text controllers with user details
      setState(() {
        _firstNameController.text = userDetails['first_name'] ?? '';
        _middleNameController.text = userDetails['middle_name'] ?? '';
        _lastNameController.text = userDetails['last_name'] ?? '';
        _genderController.text = userDetails['gender'] ?? '';
        _birthdayController.text = userDetails['birthday'] ?? '';
        _addressHouseController.text = userDetails['address_house'] ?? '';
        _addressStreetController.text = userDetails['address_street'] ?? '';
        _contactNoController.text = userDetails['contact_no'] ?? '';
        _emailAddressController.text = userDetails['email'] ?? '';
      });
    } else {
      print('User details not found');
    }
  }

  void updateDetails() {
    try {
      InputValidator.checkFormValidity(formKey, context);

      model.updateUserDetails(
        model.uId,
        _firstNameController.text.trim(),
        _middleNameController.text.trim(),
        _lastNameController.text.trim(),
        _genderController.text.trim(),
        _birthdayController.text.trim(),
        _addressHouseController.text.trim(),
        _addressStreetController.text.trim(),
      );

      Utilities.showSnackBar("Successfully Updated Details", Colors.green);
    } catch (ex) {
      Utilities.showSnackBar("$ex", Colors.red);
    }
    context.go('/profile/true');
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
        title: Text("Update Profile"),
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
                        validator: InputValidator.requiredValidator,
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
                      child: InputField(
                        inputType: "text",
                        placeholder: "Male or Female",
                        label: "Gender",
                        controller: _genderController,
                        validator: InputValidator.requiredValidator,
                      ),
                    ),
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
                        context.go('/profile/update/change-auth/phone');
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
                        context.go('/profile/update/change-auth/email');
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
