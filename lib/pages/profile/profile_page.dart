import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_capstone/constants.dart';
import 'package:irs_capstone/models/user_model.dart';
import 'package:irs_capstone/widgets/input_button.dart';

class ProfilePage extends StatefulWidget {
  final bool? reload;
  const ProfilePage({Key? key, this.reload}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel model = new UserModel();
  String userType = "";
  String full_name = "";
  String gender = "";
  String birthday = "";
  String address = "";
  String contact_no = "";
  String email = "";
  String profile_path = "https://i.stack.imgur.com/l60Hf.png";

  void deactiveAccount() async {}

  void fetchDetails() async {
    Map<String, dynamic>? userDetails = await UserModel.getUserById(model.uId);
    if (userDetails != null) {
      // Update text controllers with user details
      setState(() {
        userType = userDetails['user_type'] ?? '';
        full_name =
            "${userDetails['first_name'] ?? ''} ${userDetails['middle_name'] ?? ''} ${userDetails['last_name'] ?? ''}";
        gender = userDetails['gender'] ?? '';
        birthday = userDetails['birthday'] ?? '';
        address =
            "${userDetails['address_house'] ?? ''}, ${userDetails['address_street'] ?? ''}, Tambubong, San Rafael, Bulacan";
        contact_no = userDetails['contact_no'] ?? '';
        email = userDetails['email'] ?? '';
        profile_path = userDetails['profile_path'] ??
            "https://i.stack.imgur.com/l60Hf.png";
      });
    } else {
      print('User details not found');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchDetails();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();

    if (widget.reload != null && widget.reload == true) {
      fetchDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();

              context.go('/login');
            },
            child: Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(150),
                  child: Image.network(
                    profile_path,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(
                height: 16,
              ),
              Text(
                userType.toUpperCase(),
                style: CustomTextStyle.subheading,
              ),
              SizedBox(
                height: 16,
              ),
              ListView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.person,
                    ),
                    title: Text(full_name),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.male,
                    ),
                    title: Text(gender),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.celebration,
                    ),
                    title: Text(birthday),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.location_city,
                    ),
                    title: Text(address),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.phone_iphone,
                    ),
                    title: Text(contact_no),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.email,
                    ),
                    title: Text(email),
                  ),
                ],
              ),
              InputButton(
                label: "Edit Profile",
                function: () {
                  context.go('/profile/update');
                },
                large: false,
              ),
              InputButton(
                  label: "Change Password",
                  function: () {
                    context.go('/profile/change-password');
                  },
                  large: false),
              // InputButton(
              //   label: "Deactive Account",
              //   function: () {
              //     showDialog(
              //       context: context,
              //       builder: (context) {
              //         return AlertDialog(
              //           title: Text("Deactivate Account"),
              //           content: Text(
              //               "Are you sure you want to deactivate your account? To activate again, login in 30 days before permanent deletion."),
              //           actions: [
              //             TextButton(
              //               onPressed: () {
              //                 Navigator.of(context).pop(); // Dismiss dialog
              //               },
              //               child: Text("Cancel"),
              //             ),
              //             TextButton(
              //               onPressed: () async {
              //                 model.accountDeactivate(model.uId, true);
              //                 FirebaseAuth.instance.signOut();
              //                 context.go('/login');
              //               },
              //               child: Text("Deactivate"),
              //             ),
              //           ],
              //         );
              //       },
              //     );
              //   },
              //   large: false,
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
