import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Incident {
  final String incident_id;
  Incident({required this.incident_id});

  update(Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('incidents')
          .doc(incident_id)
          .update(data);
      return true;
    } catch (err) {
      print(err);
    }
    return false;
  }

  getTag(String incident_tag) async {
    try {
      final incidentTagDetails = await FirebaseFirestore.instance
          .collection('incident_tags')
          .doc(incident_tag)
          .get();
      return incidentTagDetails['tag_name'];
    } catch (err) {
      print(err);
    }
  }
}
