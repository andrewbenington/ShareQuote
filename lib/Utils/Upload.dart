import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pearawards/Collections/Collection.dart';
import 'package:pearawards/Utils/Converter.dart';

import 'package:pearawards/Awards/Award.dart';

Future<int> uploadNewAward(
    FirebaseUser user, Award award, DocumentReference collection, bool newTime) {
  var docRef = Firestore.instance.collection('users').document(user.uid);

  docRef.get().then((doc) {
    if (!doc.exists) {
      Firestore.instance
          .collection('users')
          .document(user.uid)
          .setData({"display": user.displayName});
    }
    collection.updateData({"lastEdit": DateTime.now().microsecondsSinceEpoch});
    return uploadAward(user, award, collection, !newTime);
  });
}

Future<int> uploadDoc(FirebaseUser user, String url, DocumentReference collection) async {
  Result result = await retrieveAwards(url);
  DocumentReference docRef =
      Firestore.instance.collection('users').document(user.uid);
  return docRef.get().then((doc) async {
    if (!doc.exists) {
      Firestore.instance
          .collection('users')
          .document(user.uid)
          .setData({"display": user.displayName});
    }
    for (Award a in result.awards) {
      int code = await uploadAward(user, a, collection, true);
      if (code != 0) {
        return code;
      }
    }
    collection.updateData(
        {"googledoc": url, "lastEdit": DateTime.now().microsecondsSinceEpoch});
    return 0;
  });
}

Future<int> uploadAward(FirebaseUser user, Award award,
    DocumentReference collection, bool fullDoc) async {
  return collection.get().then((doc) {
    var awd = collection.collection("awards").document();
    awd.setData({
      "json": jsonEncode(awardToJson(award)),
      "timestamp":
          fullDoc ? award.timestamp : DateTime.now().microsecondsSinceEpoch,
      "likes": 0
    });
    return 0;
  });
}



Future<void> addFriendCollection(
    FirebaseUser user, Collection c) async {
  var docRef = Firestore.instance.document('users/' + user.uid);

  docRef.get().then((doc) {
    if (!doc.exists) {
      Firestore.instance
          .document('users/' + user.uid)
          .setData({"display": user.displayName});
    }
    var coll = Firestore.instance
        .collection('users/' + user.uid + '/collections')
        .document();
    coll.get().then((doc) {
      if (!doc.exists) {
        Firestore.instance
            .document('users/' + user.uid + '/collections/' + c.docRef.documentID)
            .setData({
          "lastEdit": 0,
          "isPointer": true,
          "reference": c.docRef,
          "name": c.title,

        });
      }
    });
  });
}
