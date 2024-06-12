import "package:flutter/material.dart";
import "package:irs_app/constants.dart";

class NotificationTile extends StatelessWidget {
  final String id;
  final String title;
  final String body;
  final String date;
  const NotificationTile(
      {Key? key,
      required this.id,
      required this.title,
      required this.body,
      required this.date})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                color: accentColor,
              ),
              child: Icon(
                Icons.notifications,
                color: Colors.white,
              ),
            ),
            SizedBox(
              width: 8,
            ),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: majorText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    body,
                    style: TextStyle(
                      color: minorText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 8,
            ),
            Text(
              date,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            )
          ],
        ),
      ),
    );
  }
}
