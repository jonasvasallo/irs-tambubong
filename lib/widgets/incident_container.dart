import 'package:flutter/material.dart';
import 'package:irs_app/constants.dart';
import 'package:go_router/go_router.dart';

class IncidentContainer extends StatelessWidget {
  final String id;
  final String title;
  final String location;
  final String details;
  final String date;
  final bool latest;
  final int witnesses;
  const IncidentContainer({
    Key? key,
    required this.title,
    required this.location,
    required this.details,
    required this.date,
    required this.id,
    required this.latest,
    required this.witnesses,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.go('/home/incident/${id}');
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 248, 246, 246),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: (latest) ? Colors.red : minorText, width: 1),
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
                      flex: 1,
                      child: Text(
                        title.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: majorText,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      flex: 2,
                      child: Text(
                        location,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 4,
                    ),
                    Text(
                      date,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: (latest) ? Colors.red : minorText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      flex: 3,
                      child: Text(
                        details,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Row(
                      children: [
                        Icon(Icons.visibility),
                        SizedBox(
                          width: 4,
                        ),
                        Text("${witnesses}"),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
