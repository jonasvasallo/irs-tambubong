import "package:flutter/material.dart";
import 'package:irs_capstone/constants.dart';

class ProfileButton extends StatelessWidget {
  final Color iconColor;
  final String name;
  final Icon icon;
  final VoidCallback action;
  const ProfileButton({
    Key? key,
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: icon,
                    ),
                  ),
                  Text(
                    name,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: majorText),
                  ),
                ],
              ),
              Icon(
                Icons.chevron_right,
                color: accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
