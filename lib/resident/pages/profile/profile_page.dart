import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/models/user_model.dart';
import 'package:irs_app/widgets/input_button.dart';
import 'package:irs_app/widgets/profile_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
            "${userDetails['first_name'] ?? ''} ${(userDetails['middle_name'].toString().isNotEmpty) ? userDetails['middle_name'][0] : ''} ${userDetails['last_name'] ?? ''}";
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
        title: Text("Account"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  final int checkProfile = prefs.getInt("checkProfile") ?? 0;

                  if (checkProfile > 100) {
                    Utilities.showSnackBar(
                        "You are only limited to check your profile 100 times in demo version!",
                        Colors.red);
                    return;
                  }
                  prefs.setInt("checkProfile", checkProfile + 1);
                  context.go('/profile/update');
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(150),
                        child: Image.network(
                          profile_path,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hi, ${full_name}",
                          style: CustomTextStyle.subheading,
                        ),
                        Text(
                          contact_no,
                          style: CustomTextStyle.regular_minor,
                        ),
                        Text(
                          email,
                          style: CustomTextStyle.regular_minor,
                        ),
                      ],
                    )
                  ],
                ),
              ),
              SizedBox(
                height: 16,
              ),
              ProfileButton(
                name: "Change Password",
                icon: Icon(Icons.lock_open_outlined),
                iconColor: Colors.white,
                action: () {
                  context.go('/profile/change-password');
                },
              ),
              ProfileButton(
                name: "My Incidents",
                icon: Icon(Icons.history_outlined),
                iconColor: Colors.white,
                action: () {
                  context.go('/profile/incidents');
                },
              ),
              ProfileButton(
                name: "File a Complaint",
                icon: Icon(Icons.report_outlined),
                iconColor: Colors.white,
                action: () {
                  context.go('/profile/complaint');
                },
              ),
              ProfileButton(
                name: "Help",
                icon: Icon(Icons.help_outline),
                iconColor: Colors.white,
                action: () {
                  context.go('/profile/help');
                },
              ),
              ProfileButton(
                name: "Logout",
                icon: Icon(Icons.logout_outlined),
                iconColor: Colors.white,
                action: () {
                  FirebaseMessaging.instance.unsubscribeFromTopic('incident-alert');
                  FirebaseMessaging.instance.unsubscribeFromTopic('sos-alert');
                  FirebaseAuth.instance.signOut();

                  context.go('/login');
                },
              ),

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
