import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pearawards/Utils/Converter.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;

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
    globals.reads++;
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
    return 0;
  });
}

Future<int> uploadAward(String uploadPath, Award award,
    DocumentReference collection, bool fullDoc) async {
  DocumentReference awd =
      Firestore.instance.collection(uploadPath).document(award.hash.toString());
  Map<String, dynamic> m = awardToMap(award);
  m.addAll({
    "timestamp":
        fullDoc ? award.timestamp : DateTime.now().microsecondsSinceEpoch,
    "likes": 0,
    "collections": collection != null ? [collection] : null
  });
  awd.setData(m);

  if (collection != null) {
    collection.collection("awards").document(award.hash.toString()).setData({
      "reference": awd,
      "timestamp":
          fullDoc ? award.timestamp : DateTime.now().microsecondsSinceEpoch,
    });
  }

  return 0;
}

setTagReference(String path, String uid, int timestamp, String hash) async {
  HttpsCallable post =
      CloudFunctions.instance.getHttpsCallable(functionName: "taggedPost");
  await post.call({
    "uid": uid,
    "timestamp": timestamp,
    "award": path,
    "hash": hash
  }).catchError((error) {
    print(error);
    return;
  });
}

addLike(DocumentReference award, Function onFinished, bool remove) async {
  if (onFinished == null) {
    onFinished = () {};
  }
  HttpsCallable post =
      CloudFunctions.instance.getHttpsCallable(functionName: "addRemoveLike");
  await post.call({
    "remove": remove ? "true" : "false",
    "from": globals.me.uid,
    "name": globals.me.displayName,
    "award": award.path
  }).catchError((error) {
    print(error);
    onFinished(false);
    return;
  });
  onFinished(true);
}

massUploadLikes() async {
  if (globals.likeRequests.length > 1) {
    return;
  }
  Future.delayed(const Duration(seconds: 10), () {
    bool error = false;
    if (globals.likeRequests.length > 0) {
      for (MapEntry entry in globals.likeRequests.entries) {
        addLike(Firestore.instance.document(entry.key), (completed) {
          if (!completed) {
            error = true;
            String hash = entry.key.substring(entry.key.lastIndexOf('\/') + 1);
            if (entry.value) {
              globals.loadedAwards[hash].likes -= 1;
              globals.loadedAwards[hash].liked = false;
            } else {
              globals.loadedAwards[hash].likes += 1;
              globals.loadedAwards[hash].liked = true;
            }
          }
          globals.likeRequests.remove(entry.key);
        }, !entry.value);
      }
    }
    if (error) {
      print("error liking post");
    }
  });
}

Future<bool> postFollowRequest(String uid, bool unfollow) async {
  HttpsCallable post = CloudFunctions.instance
      .getHttpsCallable(functionName: "sendFollowRequest");
  var result = await post.call({
    "remove": unfollow ? "true" : "false",
    "from": globals.me.uid,
    "name": globals.me.displayName,
    "to": uid
  }).catchError((error) {
    print(error);
    return false;
  });

  print(result.data);
  return true;
}

massUploadFollows() async {
  if (globals.followRequests.length > 1) {
    return;
  }
  Future.delayed(const Duration(seconds: 10), () {
    if (globals.followRequests.length > 0) {
      for (MapEntry entry in globals.followRequests.entries) {
        postFollowRequest(entry.key, !entry.value).then((success) {
          if (success) {
            globals.followRequests.remove(entry.key);
          }
        });
      }
    }
  });
}
