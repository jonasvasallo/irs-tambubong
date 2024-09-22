import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:irs_app/core/input_validator.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/models/user_model.dart';
import 'package:irs_app/widgets/input_button.dart';
import 'package:irs_app/widgets/input_field.dart';

class WitnessPage extends StatefulWidget {
  final String id;
  const WitnessPage({Key? key, required this.id}) : super(key: key);

  @override
  _WitnessPageState createState() => _WitnessPageState();
}

class _WitnessPageState extends State<WitnessPage> {
  final _detailsController = TextEditingController();

  File? selectedImage;

  final formKey = GlobalKey<FormState>();

  Image imageShown = Image.network(
    "https://i.stack.imgur.com/l60Hf.png",
    fit: BoxFit.cover,
  );

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

  void addWitness() async {
    InputValidator.checkFormValidity(formKey, context);

    if (_detailsController.text.isEmpty) {
      Utilities.showSnackBar("Please provide details", Colors.red);
      return;
    }

    UserModel model = new UserModel();
    Map<String, dynamic>? userDetails =
        await model.getUserDetails(FirebaseAuth.instance.currentUser!.uid);

    if (userDetails != null &&
        userDetails['witness_count'] != null &&
        userDetails['witness_count'] > 5) {
      Utilities.showSnackBar(
          "You can only send witness proof 5 times in demo version!",
          Colors.red);
      return;
    }

    try {
      var urlDownload = "";
      if (selectedImage != null) {
        final path =
            "witness_attachments/${selectedImage!.path.split('/').last}";
        final ref = FirebaseStorage.instance.ref().child(path);
        UploadTask? uploadTask = ref.putFile(selectedImage!);
        final snapshot = await uploadTask!.whenComplete(() => null);
        urlDownload = await snapshot.ref.getDownloadURL();
      }
      CollectionReference collectionReference = FirebaseFirestore.instance
          .collection('incidents')
          .doc(widget.id)
          .collection('witnesses');
      collectionReference.add({
        'user_id': FirebaseAuth.instance.currentUser?.uid,
        'details': _detailsController.text.trim(),
        'media_attachment': urlDownload,
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        'witness_count': FieldValue.increment(1),
      });

      Utilities.showSnackBar(
          "Successfully submitted information", Colors.green);
    } catch (ex) {
      Utilities.showSnackBar("$ex", Colors.red);
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Witness"),
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(Icons.chevron_left),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                InputField(
                  placeholder: "Details",
                  inputType: "message",
                  controller: _detailsController,
                  validator: InputValidator.requiredValidator,
                ),
                InputButton(
                    label: "Add Attachment",
                    function: () {
                      _pickImageFromGallery();
                    },
                    large: false),
                Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey,
                  child: (selectedImage != null)
                      ? Image.file(
                          selectedImage!,
                          fit: BoxFit.cover,
                        )
                      : SizedBox(),
                ),
                SizedBox(
                  height: 16,
                ),
                InputButton(
                    label: "SUBMIT",
                    function: () {
                      addWitness();
                    },
                    large: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
