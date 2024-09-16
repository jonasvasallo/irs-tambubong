import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:irs_app/core/input_validator.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/widgets/input_button.dart';
import 'package:irs_app/widgets/input_field.dart';

class SosSendChatField extends StatefulWidget {
  final String id;
  const SosSendChatField({Key? key, required this.id}) : super(key: key);

  @override
  _SosSendChatFieldState createState() => _SosSendChatFieldState();
}

class _SosSendChatFieldState extends State<SosSendChatField> {
  final _messageController = TextEditingController();

  void sendMessage() async {
    if (_messageController.text.isEmpty) {
      Utilities.showSnackBar("Please enter a message", Colors.red);
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('sos')
          .doc(widget.id)
          .collection('chatroom')
          .add({
        'content': _messageController.text.trim(),
        'sent_by': FirebaseAuth.instance.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
      });
      _messageController.clear();
    } catch (ex) {
      Utilities.showSnackBar("$ex", Colors.red);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: InputField(
                placeholder: "Type your message here...",
                inputType: "text",
                controller: _messageController,
              ),
            ),
            SizedBox(
              width: 8,
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: InputButton(
                    label: "Send",
                    function: () {
                      sendMessage();
                    },
                    large: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
