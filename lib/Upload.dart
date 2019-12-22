import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pearawards/Converter.dart';

import 'Award.dart';

Future<int> uploadNewAward(FirebaseUser user, Award award, String collection, bool newTime) {
  var docRef = Firestore.instance.collection('users').document(user.uid);

  docRef.get().then((doc) {
    if (!doc.exists) {
      Firestore.instance
          .collection('users')
          .document(user.uid)
          .setData({"display": user.displayName});
    }
    DocumentReference coll = Firestore.instance
        .collection('users')
        .document(user.uid)
        .collection('collections')
        .document(collection);
        coll.updateData({"lastEdit": DateTime.now().microsecondsSinceEpoch});
    return uploadAward(user, award, coll, !newTime);
  });
}

Future<int> uploadDoc(FirebaseUser user, String url, String name) async {
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
    DocumentReference coll = Firestore.instance
        .collection('users')
        .document(user.uid)
        .collection('collections')
        .document(name);
    for (Award a in result.awards) {
      int code = await uploadAward(user, a, coll, true);
      if (code != 0) {
        return code;
      }
    }
    coll.setData({"googledoc" : url, "lastEdit": DateTime.now().microsecondsSinceEpoch});
    return 0;
  });
}

Future<int> uploadAward(
    FirebaseUser user, Award award, DocumentReference collection, bool fullDoc) async {
      
  return collection.get().then((doc) {
    var awd = collection.collection("awards").document();
    awd.setData({
      "json": jsonEncode(awardToJson(award)),
      "timestamp": fullDoc ? award.timestamp : DateTime.now().microsecondsSinceEpoch,
      "likes": 0
    });
    return 0;
  });
}

Future<void> createCollection(FirebaseUser user, String collection) async {
  var docRef = Firestore.instance.collection('users').document(user.uid);

  docRef.get().then((doc) {
    if (!doc.exists) {
      Firestore.instance
          .collection('users')
          .document(user.uid)
          .setData({"display": user.displayName});
    }
    var coll = Firestore.instance
        .collection('users')
        .document(user.uid)
        .collection('collections')
        .document(collection);
    coll.get().then((doc) {
      if (!doc.exists) {
        Firestore.instance
            .collection('users')
            .document(user.uid)
            .collection('collections')
            .document(collection)
            .setData({"lastEdit":0});
      }
    });
  });
}
