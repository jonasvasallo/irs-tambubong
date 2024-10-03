import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:irs_app/constants.dart';
import 'package:irs_app/core/utilities.dart';
import 'package:irs_app/models/user_model.dart';
import 'package:irs_app/widgets/comment_widget.dart';
import 'package:irs_app/widgets/custom_appbar.dart';
import 'package:irs_app/widgets/input_button.dart';
import 'package:irs_app/widgets/input_field.dart';

class NewsDetailsPage extends StatefulWidget {
  final String id;
  const NewsDetailsPage({Key? key, required this.id}) : super(key: key);

  @override
  _NewsDetailsPageState createState() => _NewsDetailsPageState();
}

class _NewsDetailsPageState extends State<NewsDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(title: "News Info"),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            NewsPartSection(id: widget.id),
            SendCommentSection(id: widget.id),
          ],
        ),
      ),
    );
  }
}

class NewsPartSection extends StatefulWidget {
  final String id;
  const NewsPartSection({Key? key, required this.id}) : super(key: key);

  @override
  _NewsPartSectionState createState() => _NewsPartSectionState();
}

class _NewsPartSectionState extends State<NewsPartSection> {
  void likeNews() async {
    try {
      UserModel model = new UserModel();
      Map<String, dynamic>? userDetails =
          await model.getUserDetails(FirebaseAuth.instance.currentUser!.uid);

      if (userDetails != null && userDetails['verified'] == false) {
        Utilities.showSnackBar("You must be verified to do this!", Colors.red);
        return;
      }

      await FirebaseFirestore.instance
          .collection('news')
          .doc(widget.id)
          .collection('likes')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({
        'liked_at': FieldValue.serverTimestamp(),
        'uid': FirebaseAuth.instance.currentUser!.uid,
      });
      await FirebaseFirestore.instance
          .collection('news')
          .doc(widget.id)
          .update({
        'like_count': FieldValue.increment(1),
      });
    } catch (ex) {
      Utilities.showSnackBar("$ex", Colors.red);
    }
    setState(() {});
  }

  void unlikeNews() async {
    try {
      await FirebaseFirestore.instance
          .collection('news')
          .doc(widget.id)
          .collection('likes')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .delete();
      await FirebaseFirestore.instance
          .collection('news')
          .doc(widget.id)
          .update({
        'like_count': FieldValue.increment(-1),
      });
    } catch (ex) {
      Utilities.showSnackBar("$ex", Colors.red);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future:
            FirebaseFirestore.instance.collection('news').doc(widget.id).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("${snapshot.error}"),
            );
          }
          final newsDetails = snapshot.data!;
          List<Widget> media_photos = [];
          for (var media in newsDetails['media_attachments']) {
            final media_photo = Padding(
              padding: EdgeInsets.only(right: 8),
              child: Container(
                width: MediaQuery.of(context).size.width - 48,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    media,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
            media_photos.add(media_photo);
          }
          return Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${newsDetails['heading']}",
                    style: CustomTextStyle.heading,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Text(
                    "${Utilities.convertDate(newsDetails['timestamp'])}",
                    style: CustomTextStyle.regular_minor,
                  ),
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
                        "Barangay Tambubong",
                        style: CustomTextStyle.regular_minor,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Text(
                    "${newsDetails['body']}",
                    style: CustomTextStyle.regular,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: media_photos,
                    ),
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('news')
                          .doc(widget.id)
                          .collection('likes')
                          .where(
                            'uid',
                            isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                          )
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text("${snapshot.error}"),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data == null) {
                          return Center();
                        }
                        final likes = snapshot.data!.docs;

                        // Check if the user liked the post
                        final userLiked = likes.isNotEmpty;

                        return Row(
                          children: [
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size(40, 40),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                (userLiked) ? unlikeNews() : likeNews();
                              },
                              child: Icon(
                                (userLiked)
                                    ? Icons.thumb_up_alt
                                    : Icons.thumb_up_alt_outlined,
                                color: accentColor,
                              ),
                            ),
                            Text(
                              "${(newsDetails.data() != null) ? (newsDetails.data()!.containsKey("like_count") ? newsDetails['like_count'] : 0) : 0}",
                              style: CustomTextStyle.regular_minor,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Icon(
                              Icons.comment,
                              color: accentColor,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              "${(newsDetails.data() != null) ? (newsDetails.data()!.containsKey("comment_count") ? newsDetails['comment_count'] : 0) : 0}",
                              style: CustomTextStyle.regular_minor,
                            ),
                          ],
                        );
                      }),
                  SizedBox(
                    height: 16,
                  ),
                  StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('news')
                        .doc(widget.id)
                        .collection('comments')
                        .orderBy('sent_at')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text("${snapshot.error}"),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data == null) {
                        return Center();
                      }
                      List<Widget> commentWidgets = [];
                      final comments = snapshot.data!.docs.toList();
                      for (var comment in comments) {
                        final commentWidget = CommentWidget(
                          uid: comment['comment_by'],
                          comment: comment['comment'],
                        );
                        commentWidgets.add(commentWidget);
                      }
                      return Column(
                        children: commentWidgets,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }
}

class SendCommentSection extends StatefulWidget {
  final String id;

  const SendCommentSection({Key? key, required this.id}) : super(key: key);

  @override
  _SendCommentSectionState createState() => _SendCommentSectionState();
}

class _SendCommentSectionState extends State<SendCommentSection> {
  final _commentController = TextEditingController();
  void sendMessage() async {
    if (_commentController.text.isEmpty) {
      Utilities.showSnackBar("Please enter a message first", Colors.red);
      return;
    }

    try {
      UserModel model = new UserModel();
      Map<String, dynamic>? userDetails =
          await model.getUserDetails(FirebaseAuth.instance.currentUser!.uid);

      if (userDetails != null && userDetails['verified'] == false) {
        Utilities.showSnackBar("You must be verified to do this!", Colors.red);
        return;
      }
      await FirebaseFirestore.instance
          .collection('news')
          .doc(widget.id)
          .collection('comments')
          .add({
        'comment': _commentController.text.trim(),
        'comment_by': FirebaseAuth.instance.currentUser!.uid,
        'sent_at': FieldValue.serverTimestamp(),
      });

      setState(() {
        _commentController.text = "";
      });
    } catch (ex) {
      Utilities.showSnackBar("$ex", Colors.red);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: InputField(
            placeholder: "Type your message here...",
            inputType: "text",
            controller: _commentController,
          ),
        ),
        SizedBox(
          width: 8,
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: InputButton(
                label: "Send",
                function: () {
                  sendMessage();
                },
                large: false),
          ),
        ),
      ],
    );
  }
}
