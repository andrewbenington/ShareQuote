import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pearawards/Utils/Converter.dart';

import 'package:pearawards/Awards/Award.dart';

Future<int> uploadNewAward(String uploadPath, Award award,
    DocumentReference collection, bool newTime) {
  if (collection != null) {
    collection.updateData({"lastEdit": DateTime.now().microsecondsSinceEpoch});
  }

  return uploadAward(uploadPath, award, collection, !newTime);
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
    }
    collection.updateData(
        {"googledoc": url, "lastEdit": DateTime.now().microsecondsSinceEpoch});
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
    "collections": [collection]
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
