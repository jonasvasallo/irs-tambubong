import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_capstone/constants.dart';
import 'package:irs_capstone/core/file_picker_util.dart';
import 'package:irs_capstone/core/input_validator.dart';
import 'package:irs_capstone/core/utilities.dart';
import 'package:irs_capstone/widgets/input_button.dart';
import 'package:irs_capstone/widgets/input_field.dart';

class KnownComplaintPage extends StatefulWidget {
  const KnownComplaintPage({Key? key}) : super(key: key);

  @override
  _KnownComplaintPageState createState() => _KnownComplaintPageState();
}

class _KnownComplaintPageState extends State<KnownComplaintPage> {
  List<Widget> media_photosers = [];
  late FilePickerUtil filePickerUtil;

  final _fullNameController = TextEditingController();
  final _natureController = TextEditingController();

  late StreamController<List<Map<String, dynamic>>> _streetsStreamController;
  late List<Map<String, dynamic>> _streets;

  String user_id = "";

  String _dropdownValue = "";

  final formKey = GlobalKey<FormState>();

  void fileComplaint() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (_dropdownValue.isEmpty) {
      Utilities.showSnackBar("You must select the address first", Colors.red);
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
      List<String> imageUrls = [];

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      Map<String, dynamic> user_Details = {};
      if (userDoc.exists) {
        print(userDoc.data());
        user_Details = userDoc.data() as Map<String, dynamic>;
      } else {
        print('Document does not exist');
        return;
      }

      if (filePickerUtil.pickedImagesInBytes.length > 0) {
        imageUrls = await filePickerUtil.uploadMultipleFiles(
            "${user_Details['first_name']}-${user_Details['last_name']}_${FirebaseAuth.instance.currentUser!.uid}");
        print(imageUrls);
      }

      CollectionReference complaintsCollection =
          FirebaseFirestore.instance.collection('complaints');

      await complaintsCollection.add({
        'full_name':
            "${user_Details['first_name']} ${user_Details['last_name']}",
        'contact_no': "${user_Details['contact_no']}",
        'email': user_Details['email'],
        'address':
            "${user_Details['address_house']} ${user_Details['address_street']}",
        'respondent_info': [
          _fullNameController.text,
          'N/A',
          "${_dropdownValue}, Tambubong, San Rafael, Bulacan",
        ],
        'respondent_id': user_id,
        'respondent_description': "",
        "description": _natureController.text.trim(),
        'supporting_docs': imageUrls,
        'issued_at': FieldValue.serverTimestamp(),
        'issued_by': FirebaseAuth.instance.currentUser!.uid,
        'status': "Open",
      });
      Utilities.showSnackBar("Successfully filed complaint", Colors.green);
      Navigator.of(dialogContext).pop();
      context.go('/profile');
    } catch (ex) {
      Utilities.showSnackBar("$ex", Colors.red);
      Navigator.of(dialogContext).pop();
    }
  }

  @override
  void initState() {
    super.initState();
    filePickerUtil = FilePickerUtil("complaints_documents", () {
      setState(() {});
    }, media_photosers);
    _streetsStreamController = StreamController<List<Map<String, dynamic>>>();
    _streets = [];

    // Fetch incident tags when the widget is initialized
    getStreets().then((tags) {
      _streetsStreamController.add(tags);
    });
  }

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("File a Complaint"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InputField(
                  placeholder: "Name",
                  inputType: "text",
                  controller: _fullNameController,
                  label: "Individual's Name",
                  validator: InputValidator.requiredValidator,
                ),
                SizedBox(
                  height: 8,
                ),
                Text(
                  "OR",
                  style: CustomTextStyle.regular_minor,
                ),
                TextButton(
                  onPressed: () {
                    showBottomSheet(
                      context: context,
                      builder: (context) {
                        return SearchUserPage(onSelect: (name, uID) {
                          print(name);
                          user_id = uID;
                          _fullNameController.text = name;
                        });
                      },
                    );
                  },
                  child: Text(
                    "Search User",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                          _dropdownValue = value;
                        },
                        dropdownMenuEntries:
                            _incidentTags.map((Map<String, dynamic> tag) {
                          return DropdownMenuEntry(
                              value: tag['street_id'],
                              label: "${tag['street_name']} Street");
                        }).toList(),
                      );
                    }
                  },
                ),
                SizedBox(
                  height: 8,
                ),
                InputField(
                  placeholder: "Nature of the complaint...",
                  inputType: "message",
                  controller: _natureController,
                  label: "Nature of complaint",
                  validator: InputValidator.requiredValidator,
                ),
                Text(
                  "Please provide a concise and precise description of your complaint.",
                  style: CustomTextStyle.regular_minor,
                  textAlign: TextAlign.left,
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      filePickerUtil.selectAFile();
                    });
                    setState(() {});
                    setState(() {});
                  },
                  child: Text(
                    "Attach Media",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: filePickerUtil.media_photos,
                  ),
                ),
                SizedBox(
                  height: 16,
                ),
                InputButton(
                  label: "Submit Complaint",
                  function: () {
                    fileComplaint();
                  },
                  large: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SearchUserPage extends StatefulWidget {
  final Function(String name, String uID) onSelect;
  const SearchUserPage({Key? key, required this.onSelect}) : super(key: key);

  @override
  _SearchUserPageState createState() => _SearchUserPageState();
}

class _SearchUserPageState extends State<SearchUserPage> {
  final _searchController = TextEditingController();

  List _allResults = [];
  List _resultList = [];

  getUserStream() async {
    var data = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('first_name')
        .get();

    setState(() {
      _allResults = data.docs;
    });
    searchResultList();
  }

  _onSearchChanged() {
    print(_searchController.text);
    searchResultList();
  }

  searchResultList() {
    var showResults = [];

    if (_searchController.text != null) {
      for (var userSnapshot in _allResults) {
        var name =
            "${userSnapshot['first_name'].toString().toLowerCase()} ${userSnapshot['last_name'].toString().toLowerCase()}";

        if (name.contains(_searchController.text.toLowerCase())) {
          showResults.add(userSnapshot);
        }
      }
    } else {
      showResults = List.from(_allResults);
    }

    setState(() {
      _resultList = showResults;
    });
  }

  @override
  void initState() {
    getUserStream();
    _searchController.addListener(_onSearchChanged);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    getUserStream();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            InputField(
              placeholder: "Search User",
              inputType: "text",
              controller: _searchController,
            ),
            InputButton(
              label: "SEARCH",
              function: () {},
              large: true,
            ),
            Expanded(
              child: ListView.builder(
                  itemCount: _resultList.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () {
                        widget.onSelect(
                          "${_resultList[index]['first_name']} ${_resultList[index]['last_name']}",
                          _resultList[index].id,
                        );
                        Navigator.of(context).pop();
                      },
                      title: Text(
                        "${_resultList[index]['first_name']} ${_resultList[index]['last_name']}",
                      ),
                      subtitle: Text(
                        "${_resultList[index]['address_house']} ${_resultList[index]['address_street']}, Tambubong",
                      ),
                    );
                  }),
            )
          ],
        ),
      ),
    );
  }
}
