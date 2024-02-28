import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  String uId = "";
  final CollectionReference users = FirebaseFirestore.instance.collection(
    'users',
  );

  UserModel() {
    String uID;
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      uID = user.uid;
    } else {
      uID = "";
    }
    uId = uID;
  }

  static Future<Map<String, dynamic>?> getUserById(String userId) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      print(userDoc.data());
      return userDoc.data() as Map<String, dynamic>;
    } else {
      print('Document does not exist');
    }
  }

  Future<void> updateUserDetails(
    String docID,
    String first_name,
    String middle_name,
    String last_name,
    String gender,
    String birthday,
    String address_house,
    String address_street,
  ) {
    return users.doc(docID).update({
      'first_name': first_name,
      'middle_name': middle_name,
      'last_name': last_name,
      'gender': gender,
      'birthday': birthday,
      'address_house': address_house,
      'address_street': address_street,
    });
  }

  Future<void> changeEmail(
    String email,
    String password,
    String newEmail,
  ) async {
    User user = FirebaseAuth.instance.currentUser!;
    EmailAuthProvider.credential(email: email, password: password);
    await user.updateEmail(newEmail);
    users.doc(uId).update({
      'email': newEmail,
    });
  }

  Future<void> changePhoneNo(
      String phoneNumber, String smsCode, String newPhoneNo) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseAuth.instance.verifyPhoneNumber(
          verificationCompleted: (PhoneAuthCredential credential) async {},
          verificationFailed: (FirebaseAuthException ex) {
            print(ex);
          },
          codeSent: (String verificationId, int? resendToken) async {
            PhoneAuthCredential credential = PhoneAuthProvider.credential(
              verificationId:
                  verificationId, // You should obtain the verification ID from a previous authentication
              smsCode:
                  smsCode, // You should obtain the SMS code from a previous authentication
            );
            await user.reauthenticateWithCredential(credential);

            // Update the phone number
            await user.updatePhoneNumber(credential);

            users.doc(uId).update({
              'contact_no': newPhoneNo,
            });
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
          phoneNumber: newPhoneNo,
        );

        // Phone number updated successfully
        print('Phone number updated successfully');
      }
    } catch (ex) {
      print(ex);
    }
  }

  Future<void> accountDeactivate(String docID, bool value) async {
    return users.doc(docID).update({
      'deactivation': value,
    });
  }

  Future<void> loginTimestamp(String docID) async {
    try {
      await users.doc(docID).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
      print('Last login timestamp updated successfully.');
    } catch (e) {
      print('Error updating last login timestamp: $e');
      // Handle error as needed
    }
  }

  Future<bool> deleteInactiveUser(String docID) async {
    try {
      DocumentSnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').doc(docID).get();

      if (snapshot.exists) {
        Map<String, dynamic> userDetails =
            snapshot.data() as Map<String, dynamic>;
        print('User document snapshot: ${snapshot.data()}');

        Timestamp? lastLoginTimestamp = userDetails['lastLogin'];
        bool deactivate = (userDetails['deactivation'] as bool) ?? false;

        if (lastLoginTimestamp != null && deactivate) {
          Timestamp currentTimestamp = Timestamp.now();
          int differenceInMilliseconds =
              currentTimestamp.millisecondsSinceEpoch -
                  lastLoginTimestamp.millisecondsSinceEpoch;
          int differenceInDays =
              differenceInMilliseconds ~/ (1000 * 60 * 60 * 24);

          if (differenceInDays > 30) {
            users.doc(this.uId).delete();
            await FirebaseAuth.instance.currentUser?.delete();
            print('User deleted due to inactivity.');
            return true; // User deleted successfully
          } else {
            print('User has logged in within the last 30 days.');

            this.accountDeactivate(this.uId, false);
            return false; // User not deleted
          }
        } else {
          print(
              'User is not marked for deactivation or last login timestamp is missing.');
          return false; // User not deleted
        }
      } else {
        print('User document not found.');
        return false; // User not deleted
      }
    } catch (e) {
      print('Error deleting user: $e');
      return false; // User not deleted due to error
    }
  }
}
