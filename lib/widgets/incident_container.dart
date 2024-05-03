import 'package:flutter/material.dart';
import 'package:irs_capstone/constants.dart';
import 'package:go_router/go_router.dart';

class IncidentContainer extends StatelessWidget {
  final String id;
  final String title;
  final String details;
  final String date;
  const IncidentContainer(
      {Key? key,
      required this.title,
      required this.details,
      required this.date,
      required this.id})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.go('/reports/incident/${id}');
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 248, 246, 246),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: minorText, width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      flex: 3,
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: CustomTextStyle.subheading,
                      ),
                    ),
                    Text(
                      date,
                      overflow: TextOverflow.ellipsis,
                      style: CustomTextStyle.regular,
                    ),
                  ],
                ),
                Text(
                  details,
                  overflow: TextOverflow.ellipsis,
                  style: CustomTextStyle.regular_minor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
