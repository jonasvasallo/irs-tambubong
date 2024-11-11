import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:irs_app/core/input_validator.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/widgets/input_button.dart';
import 'package:irs_app/widgets/input_field.dart';

class TemporaryResidencePopup extends StatefulWidget {
  const TemporaryResidencePopup({Key? key}) : super(key: key);

  @override
  _TemporaryResidencePopupState createState() =>
      _TemporaryResidencePopupState();
}

class _TemporaryResidencePopupState extends State<TemporaryResidencePopup> {
  final _landlordNameController = TextEditingController();
  final _landlordContactController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String errorMessage = "";
  bool loading = false;

  File? selectedImage;

  Future<void> _pickImageFromGallery(ValueSetter<File?> onFilePicked) async {
    final returnedImage =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (returnedImage == null) return;

    final pickedFile = File(returnedImage.path);

    setState(() {
      onFilePicked(pickedFile); // Update the image
    });
  }

  Future<String> uploadImageToFirebase(File? givenImage) async {
    try {
      if (givenImage != null) {
        final path = 'user_verifications/${givenImage!.path.split('/').last}';

        final ref = FirebaseStorage.instance.ref().child(path);
        UploadTask? uploadTask = ref.putFile(givenImage!);

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

  void provideResidencyProof() async {
    setState(() {
      errorMessage = "";
    });
    if (selectedImage == null) {
      setState(() {
        errorMessage = "Please provide the document";
      });
      return;
    }
    final isValid = formKey.currentState!.validate();
    if (!isValid) {
      return;
    }

    try {
      print("this works");
      var photoUrl = await uploadImageToFirebase(selectedImage);
      print("photo is uploaded");
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        'temporary_proof': photoUrl,
        'landlord_name': _landlordNameController.text.trim(),
        'landlord_contact': _landlordContactController.text.trim(),
      });
      print("user is updated");
      Navigator.of(context).pop();
      context.go('/profile/true');
    } catch (err) {
      setState(() {
        errorMessage = err.toString();
      });
    }
  }

  @override
  void dispose() {
    _landlordNameController.dispose();
    _landlordContactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Provide your details again"),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              Text(
                  "As a renter or temporary resident, your ID may have a different address, please provide one or more of the following documents to verify your local residency:"),
              Text(
                  "1. A recent utility bill\n2. A rental agreement\n3. Official Mail\n4. Certification from your homeowner or landlord"),
              SizedBox(
                height: 8,
              ),
              Text(
                  "Note: The document must be showing your name and barangay address"),
              SizedBox(
                height: 8,
              ),
              TextButton(
                onPressed: () {
                  _pickImageFromGallery((file) => selectedImage = file);
                },
                child: Text(
                  "Upload Document",
                  style: TextStyle(fontWeight: FontWeight.bold),
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
              SizedBox(
                height: 8,
              ),
              InputField(
                label: "Landlord Name",
                placeholder: "Landlord Name",
                inputType: "text",
                controller: _landlordNameController,
                validator: InputValidator.requiredValidator,
              ),
              InputField(
                label: "Landlord Contact No.",
                placeholder: "Landlord Contact No.",
                inputType: "phone",
                controller: _landlordContactController,
                validator: InputValidator.phoneValidator,
              ),
              SizedBox(
                height: 8,
              ),
              (errorMessage.isNotEmpty)
                  ? Text(
                      errorMessage,
                      style: TextStyle(color: Colors.red),
                    )
                  : SizedBox(),
            ],
          ),
        ),
      ),
      actions: [
        (loading)
            ? CircularProgressIndicator()
            : TextButton(
                onPressed: () {
                  provideResidencyProof();
                },
                child: Text("Submit"),
              ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text("Cancel"),
        ),
      ],
    );
  }
}
