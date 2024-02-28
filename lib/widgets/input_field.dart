import 'package:flutter/material.dart';
import 'package:irs_capstone/constants.dart';

class InputField extends StatefulWidget {
  final String placeholder;
  final String inputType;
  final String? label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final Icon? prefixIcon;
  final void Function()? onTap;
  const InputField({
    Key? key,
    required this.placeholder,
    required this.inputType,
    this.label,
    required this.controller,
    this.validator,
    this.prefixIcon,
    this.onTap,
  }) : super(key: key);

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  Future<void> _selectDate() async {
    DateTime? _picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );

    if (_picked != null) {
      setState(() {
        widget.controller.text = _picked.toString().split(" ")[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label ?? "",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: majorText,
            ),
          ),
          SizedBox(
            height: 4,
          ),
          TextFormField(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: widget.validator,
            controller: widget.controller,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: majorText,
            ),
            cursorHeight: 16,
            decoration: InputDecoration(
              prefixIcon: widget.prefixIcon,
              hintText: widget.placeholder,
              contentPadding: EdgeInsets.all(8),
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFFEBEBEB),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: accentColor,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            cursorColor: accentColor,
            obscureText: (widget.inputType == "password") ? true : false,
            keyboardType: (widget.inputType == "email")
                ? TextInputType.emailAddress
                : TextInputType.text,
            readOnly: (widget.inputType == 'date') ? true : false,
            onTap: () {
              if (widget.inputType == 'date') {
                _selectDate();
              }
            },
          ),
        ],
      ),
    );
  }
}
