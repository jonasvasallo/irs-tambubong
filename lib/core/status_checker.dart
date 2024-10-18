import 'package:cloud_firestore/cloud_firestore.dart';

class StatusChecker {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if a document exists in any collection with dynamic conditions
  Future<bool> hasActiveDocument({
    required String collectionName,
    required String userIdField,
    required String userId,
    required String statusField,
    required List<String> activeStatuses,
  }) async {
    try {
      // Query the specified collection for documents matching the userId and status criteria
      final querySnapshot = await _firestore.collection(collectionName)
          .where(userIdField, isEqualTo: userId)
          .where(statusField, whereIn: activeStatuses)
          .get();

      // Return true if any document exists with the matching conditions
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking collection $collectionName: $e');
      return false;
    }
  }
}
