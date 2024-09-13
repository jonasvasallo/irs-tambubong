import 'package:flutter/material.dart';
import 'package:irs_app/constants.dart';
import 'package:timeline_tile/timeline_tile.dart';

class IncidentTimelineTile extends StatelessWidget {
  final String date;
  final String content;
  final bool isFirst;
  final bool isLast;
  const IncidentTimelineTile(
      {Key? key, required this.date, required this.content, required this.isFirst, required this.isLast})
      : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Container(
      child: TimelineTile(
        isFirst: isFirst,
        isLast: isLast,
        beforeLineStyle: LineStyle(color: Color.fromARGB(255, 181, 204, 248)),
        indicatorStyle: IndicatorStyle(
          width: 10,
          color: Color.fromARGB(255, 207, 207, 207),
        ),
        endChild: Container(
          width: MediaQuery.of(context).size.width - 32,
          padding: padding16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              SizedBox(
                width: 16,
              ),
              Flexible(
                child: Text(
                  content,
                  style: TextStyle(
                    color: majorText,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.visible, // Allows for content to expand.
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
