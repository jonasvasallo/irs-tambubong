import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:irs_app/core/utilities.dart';

class FilePickerUtil {
  int imageCounts = 0;

  String selectFile = "";
  List<Uint8List> pickedImagesInBytes = [];

  final String folder;
  final VoidCallback setStateCallback;
  List<Widget> media_photos;

  FilePickerUtil(this.folder, this.setStateCallback, this.media_photos);

  void selectAFile() async {
    FilePickerResult? fileResult = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: true,
      type: FileType.image,
    );

    if (fileResult != null) {
      if (fileResult != null) {
        if (fileResult.files.length > 2) {
          Utilities.showSnackBar(
              "You can only select 2 files to be uploaded in demo version!",
              Colors.red);
          return;
        }
      }
      selectFile = fileResult.files.first.name;
      setStateCallback();
      fileResult.files.forEach((element) {
        pickedImagesInBytes.add(element.bytes!);
        media_photos.add(
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 8),
            child: Container(
              width: 300,
              height: 150,
              color: Colors.black,
              child: Image.memory(element.bytes!),
            ),
          ),
        );
        imageCounts++;
        setStateCallback();
      });
    } else {
      print("test");
    }
    print(selectFile);
  }

  Future<List<String>> uploadMultipleFiles(String itemName) async {
    List<String> imageUrls = [];
    try {
      for (var i = 0; i < imageCounts; i++) {
        print("uploading $i");
        Reference ref =
            FirebaseStorage.instance.ref().child('${folder}/${itemName}_$i');

        final metadata = SettableMetadata(contentType: 'image/jpeg');
        UploadTask uploadTask = ref.putData(pickedImagesInBytes[i], metadata);

        // Wait for the upload task to complete
        TaskSnapshot snapshot = await uploadTask;

        // Get the download URL
        String imageUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(imageUrl);
      }
      return imageUrls;
    } catch (ex) {
      print('Error uploading image to Firestore: $ex');
      throw ex;
    }
  }
}
