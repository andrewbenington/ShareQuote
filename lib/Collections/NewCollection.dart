import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> createCollection(FirebaseUser user, String name) async {
  var docRef = Firestore.instance.document('users/' + user.uid);

  docRef.get().then((doc) {
    if (!doc.exists) {
      Firestore.instance
          .document('users/' + user.uid)
          .setData({"display": user.displayName});
    }
    var coll = Firestore.instance
        .collection('users/' + user.uid + '/collections')
        .document()
        .setData({"lastEdit": 0, "isPointer": false, "name": name, "owner": user.uid});
  });
}