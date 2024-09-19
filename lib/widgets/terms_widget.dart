import 'package:flutter/material.dart';
import 'package:irs_app/constants.dart';

class TermsWidget extends StatelessWidget {
  final String head;
  final String body;
const TermsWidget({ Key? key, required this.head, required this.body }) : super(key: key);

  @override
  Widget build(BuildContext context){
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8,),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(head, style: CustomTextStyle.subheading,),
          Text(body, style: CustomTextStyle.regular, textAlign: TextAlign.justify,),
        ],
      ),
    );
  }
}