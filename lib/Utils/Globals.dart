library sharequote.globals;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:pearawards/Collections/Collection.dart';
import 'package:pearawards/Profile/User.dart';

FirebaseAuth firebaseAuth;
FirebaseUser firebaseUser;

Map<String, Collection> loadedCollections = Map();
Map<String, User> loadedUsers = Map();

loadUser(String uid) async {
  if (loadedUsers.containsKey(uid)) {
    return;
  }
  loadedUsers[uid] = null;
  DocumentSnapshot userSnapshot =
      (await Firestore.instance.document('users/' + uid).get());
  loadedUsers[uid] = User(
      displayName: userSnapshot.data["display"],
      uid: uid,
      imageUrl: userSnapshot.data["image"]);
  loadedUsers[uid].lastUpdated = DateTime.now().microsecondsSinceEpoch;
}
