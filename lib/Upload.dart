import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pearawards/Converter.dart';

import 'Award.dart';

void UploadDoc(FirebaseUser user, String url, String name) async {
  Result result = await retrieveAwards(url);
  for (Award a in result.awards) {
    await UploadAward(user, a, name);
  }
}

Future<void> UploadAward(
    FirebaseUser user, Award award, String collection) async {
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
            .setData({});
      }
      var awd = Firestore.instance
          .collection('users')
          .document(user.uid)
          .collection('collections')
          .document(collection)
          .collection("awards")
          .document();
      awd.setData({
        "json": jsonEncode(awardToJson(award)),
        "timestamp": DateTime.now().microsecondsSinceEpoch,
        "likes" : 0
      });
    });
  });
}

Future<void> CreateCollection(FirebaseUser user, String collection) async {
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
            .setData({});
      }
    });
  });
}
