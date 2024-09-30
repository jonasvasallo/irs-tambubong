import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/input_validator.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/models/user_model.dart';
import 'package:irs_app/widgets/input_button.dart';
import 'package:irs_app/widgets/input_field.dart';

class AdminChangeEmailPage extends StatefulWidget {
  final String email;
  const AdminChangeEmailPage({Key? key, required this.email}) : super(key: key);

  @override
  _AdminChangeEmailPageState createState() => _AdminChangeEmailPageState();
}

class _AdminChangeEmailPageState extends State<AdminChangeEmailPage> {
  final _newEmailController = TextEditingController();
  final _passwordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  void changeEmail() async {
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
      UserModel model = new UserModel();
      await model.changeEmail(
        widget.email ?? '',
        _passwordController.text.trim(),
        _newEmailController.text.trim(),
      );
      Navigator.pop(dialogContext);
      Utilities.showSnackBar("Successfully Updated Email", Colors.green);
      context.go('/admin_profile/true');
    } on FirebaseAuthException catch (ex) {
      print(ex);
      Navigator.pop(dialogContext);
      Utilities.showSnackBar("${ex.message}", Colors.red);
    }
  }

  @override
  void dispose() {
    _newEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Change Email"),
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(Icons.chevron_left),
        ),
      ),
      body: Form(
        key: formKey,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                InputField(
                  placeholder: "New Email Address",
                  inputType: 'email',
                  controller: _newEmailController,
                  label: "New Email Address",
                ),
                Text("Enter your password to change your email"),
                InputField(
                  placeholder: "Password",
                  inputType: 'password',
                  controller: _passwordController,
                  label: "Password",
                ),
                InputButton(
                  label: "Change Email",
                  function: () {
                    changeEmail();
                  },
                  large: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
