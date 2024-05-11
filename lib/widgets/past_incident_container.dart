import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_capstone/constants.dart';

class PastIncidentContainer extends StatelessWidget {
  final String id;
  final String date;
  final String title;
  final String location;
  final String type;
  const PastIncidentContainer(
      {Key? key,
      required this.id,
      required this.date,
      required this.title,
      required this.location,
      required this.type})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (type == 'emergency') {
          context.go('/profile/incidents/emergency/${id}');
        } else {
          context.go('/profile/incidents/${id}');
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Color.fromRGBO(0, 67, 101, 0.08),
                  blurRadius: 50,
                  offset: Offset(0, 5))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: MediaQuery.of(context).size.width - 32,
                color: Colors.grey.shade200,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    date,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: majorText,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: majorText,
                      ),
                    ),
                    Text(
                      location,
                      style: CustomTextStyle.regular_minor,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
