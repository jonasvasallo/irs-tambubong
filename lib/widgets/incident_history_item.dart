import 'package:flutter/material.dart';
import 'package:irs_capstone/constants.dart';

class IncidentHistoryItem extends StatelessWidget {
  final String title;
  final String tag;
  final String status;
  final String date;
  const IncidentHistoryItem(
      {Key? key,
      required this.title,
      required this.tag,
      required this.status,
      required this.date})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                  color: Color.fromRGBO(0, 67, 101, 0.08),
                  blurRadius: 50,
                  offset: Offset(0, 5))
            ]),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: CustomTextStyle.subheading,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      tag,
                      style: CustomTextStyle.regular,
                    ),
                    Text(status),
                  ],
                ),
              ),
              SizedBox(
                width: 8,
              ),
              Text(
                date,
                style: CustomTextStyle.regular_minor,
              )
            ],
          ),
        ),
      ),
    );
  }
}
