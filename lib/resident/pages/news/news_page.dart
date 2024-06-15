import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:irs_app/constants.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({Key? key}) : super(key: key);

  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("News"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "News and Announcements",
                    style: CustomTextStyle.heading,
                  ),
                  Text(
                    "Latest updates and news",
                    style: CustomTextStyle.regular_minor,
                  ),
                ],
              ),
            ),
            StreamBuilder(
                stream:
                    FirebaseFirestore.instance.collection('news').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return Text("Error ${snapshot.error}");
                  }
                  List<Widget> newsContainers = [];
                  var newsPosts = snapshot.data!.docs.toList();
                  for (var post in newsPosts) {
                    String myDate = "test";
                    if (post['timestamp'] != null) {
                      Timestamp t = post['timestamp'] as Timestamp;
                      DateTime date = t.toDate();
                      myDate = DateFormat('MM/dd hh:mm').format(date);
                    }
                    String photoUrl =
                        "https://t4.ftcdn.net/jpg/04/70/29/97/360_F_470299797_UD0eoVMMSUbHCcNJCdv2t8B2g1GVqYgs.jpg";
                    if (post['media_attachments'].length > 0) {
                      photoUrl = post['media_attachments'][0];
                    }
                    final newsWidget = NewsContainer(
                        id: post.id,
                        title: post['heading'],
                        date: myDate,
                        image: photoUrl);
                    newsContainers.add(newsWidget);
                  }
                  return Column(
                    children: newsContainers,
                  );
                })
          ],
        ),
      ),
    );
  }
}

class NewsContainer extends StatelessWidget {
  final String id;
  final String title;
  final String date;
  final String image;
  const NewsContainer(
      {Key? key,
      required this.id,
      required this.title,
      required this.date,
      required this.image})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/news/details/${id}'),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: minorText, width: 1),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person_rounded,
                    color: majorText,
                    size: 16,
                  ),
                  SizedBox(
                    width: 4,
                  ),
                  Text(
                    "Admin",
                    style: CustomTextStyle.regular_minor,
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
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 50,
                          child: Text(
                            title,
                            style: TextStyle(
                              color: majorText,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Text(
                          date,
                          style: CustomTextStyle.regular_minor,
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          image,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
