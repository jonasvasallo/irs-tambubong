import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:irs_capstone/constants.dart';
import 'package:irs_capstone/widgets/input_field.dart';

class RatingContainer extends StatefulWidget {
  final String id;
  final String name;
  final String userType;
  final String profileURL;
  final Function(String, double, String) onUpdateRatingData;
  const RatingContainer(
      {Key? key,
      required this.id,
      required this.name,
      required this.userType,
      required this.profileURL,
      required this.onUpdateRatingData})
      : super(key: key);

  @override
  State<RatingContainer> createState() => _RatingContainerState();
}

class _RatingContainerState extends State<RatingContainer> {
  final _ratingMessageController = TextEditingController();
  String rating_name = "Very Satisfied";

  double current_value = 5;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        width: MediaQuery.of(context).size.width - 32,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Color.fromRGBO(0, 67, 101, 0.08),
                blurRadius: 50,
                offset: Offset(0, 5))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey,
                    child: Image.network(
                      widget.profileURL,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: majorText,
                        ),
                      ),
                      Text(
                        widget.userType.toUpperCase(),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                height: 16,
              ),
              Row(
                children: [
                  Text(
                    "Rating",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: majorText,
                    ),
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  RatingBar(
                    minRating: 1,
                    maxRating: 5,
                    initialRating: 5,
                    allowHalfRating: false,
                    itemSize: 28,
                    glowColor: Colors.lightGreen,
                    glowRadius: 5,
                    updateOnDrag: true,
                    ratingWidget: RatingWidget(
                      full: Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      half: Icon(
                        Icons.star_half,
                        color: Colors.amber,
                      ),
                      empty: Icon(
                        Icons.star_border,
                        color: Colors.amber,
                      ),
                    ),
                    onRatingUpdate: (value) {
                      setState(() {
                        switch (value) {
                          case 1:
                            rating_name = "Very Dissatisfied";
                            break;
                          case 2:
                            rating_name = "Dissatisfied";
                            break;
                          case 3:
                            rating_name = "Fair";
                            break;
                          case 4:
                            rating_name = "Satisfied";
                            break;
                          case 5:
                            rating_name = "Very Satisfied";
                            break;
                          default:
                            rating_name = "${value}";
                            break;
                        }
                        current_value = value;
                        widget.onUpdateRatingData(widget.id, current_value,
                            _ratingMessageController.text);
                      });
                    },
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Text(
                    "${rating_name}",
                  ),
                ],
              ),
              InputField(
                placeholder: "Leave your thoughts here",
                inputType: "message",
                controller: _ratingMessageController,
                onChange: (p0) {
                  widget.onUpdateRatingData(widget.id, current_value, p0);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
