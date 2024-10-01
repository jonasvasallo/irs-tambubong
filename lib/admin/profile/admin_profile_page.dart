import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/models/user_model.dart';
import 'package:irs_app/widgets/profile_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminProfilePage extends StatefulWidget {
  final bool? reload;
  const AdminProfilePage({Key? key, this.reload}) : super(key: key);

  @override
  _AdminProfilePageState createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
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
                  context.go('/admin_profile/update');
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
                  context.go('/admin_profile/change-password');
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
            ],
          ),
        ),
      ),
    );
  }
}
