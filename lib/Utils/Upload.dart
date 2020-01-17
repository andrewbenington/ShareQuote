import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pearawards/Utils/Converter.dart';

import 'package:pearawards/Awards/Award.dart';

Future<void> uploadNewAward(String uploadPath, Award award,
    DocumentReference collection, bool newTime) {
  if (collection != null) {
    collection.updateData({"lastEdit": DateTime.now().microsecondsSinceEpoch});
  }

  uploadAward(uploadPath, award, collection, !newTime);
  if (collection != null) {
    collection.setData({
      "awardEdits": {
        award.hash.toString(): DateTime.now().microsecondsSinceEpoch
      }
    }, merge: true);
  }
}

Future<int> uploadDoc(
    FirebaseUser user, String url, DocumentReference collection) async {
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
      int code = await uploadAward(
          collection.path + "/document_awards", a, collection, true);
      if (code != 0) {
        return code;
      }
      collection.setData({
        "googledoc": url,
        "awardEdits": {a.hash.toString(): DateTime.now().microsecondsSinceEpoch}
      }, merge: true);
    }
    int time = DateTime.now().microsecondsSinceEpoch;
    collection.setData(
        Map.fromIterable(result.awards,
            key: (a) => a.award.hash.toString(), value: (a) => time),
        merge: true);
    return 0;
  });
}

Future<int> uploadAward(String uploadPath, Award award,
    DocumentReference collection, bool fullDoc) async {
  DocumentReference awd =
      Firestore.instance.collection(uploadPath).document(award.hash.toString());
  awd.setData({
    "json": jsonEncode(awardToJson(award)),
    "timestamp":
        fullDoc ? award.timestamp : DateTime.now().microsecondsSinceEpoch,
    "likes": 0,
    "collections": collection != null ? [collection] : null
  });

  if (collection != null) {
    collection.collection("awards").document(award.hash.toString()).setData({
      "reference": awd,
      "timestamp":
          fullDoc ? award.timestamp : DateTime.now().microsecondsSinceEpoch,
    });
  }

  return 0;
}
