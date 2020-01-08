import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<bool> createCollection(FirebaseUser user, String name) async {
  var docRef = Firestore.instance.document('users/${user.uid}');

  DocumentSnapshot userSnap = await docRef.get();

  if (!userSnap.exists) {
    Firestore.instance
        .document('users/${user.uid}')
        .setData({"display": user.displayName});
  }
  DocumentReference document =
      Firestore.instance.collection('collections').document();
  await document.setData({
    "lastEdit": DateTime.now().microsecondsSinceEpoch,
    "name": name,
    "owner": user.uid
  });
  await addCollectionReference(user, document, name);
}

Future<void> addCollectionReference(
    FirebaseUser user, DocumentReference document, String title) async {
  var docRef = Firestore.instance.document('users/${user.uid}');

  docRef.get().then((doc) {
    if (!doc.exists) {
      Firestore.instance
          .document('users/${user.uid}')
          .setData({"display": user.displayName});
    }
    var coll = Firestore.instance
        .collection('users/${user.uid}/collections')
        .document();
    coll.get().then((doc) {
      if (!doc.exists) {
        Firestore.instance
            .document(
                'users/${user.uid}/collections/${document.documentID}')
            .setData({
          "reference": document,
          "name": title,
        });
      }
    });
  });
}
