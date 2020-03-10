import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Profile/ProfilePage.dart';
import 'package:pearawards/Profile/User.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;

class PrimitiveWrapper {
  dynamic value = false;
  PrimitiveWrapper(this.value);
}

void rebuildAllChildren(BuildContext context) {
  void rebuild(Element el) {
    el.markNeedsBuild();
    el.visitChildren(rebuild);
  }

  (context as Element).visitChildren(rebuild);
}

String incrementString(String s) {
  if (s == "" || s == null) {
    return null;
  }
  AsciiCodec codec = AsciiCodec();
  List<int> list;
  try {
    list = codec.encode(s);
  } catch (e) {
    return null;
  }

  if (list[list.length - 1] > 127) {
    return null;
  } else {
    String incremented;
    if (list[list.length - 1] == 127) {
      incremented = incrementString(s.substring(0, s.length - 1)) + '\0';
    } else {
      incremented = s.substring(0, s.length - 1) +
          codec.decode([list[list.length - 1] + 1]);
    }
    print('incremented $s to $incremented');
    return incremented;
  }
}

void sendNotification(String uid, Map<String, dynamic> fields) async {
  HttpsCallable post = CloudFunctions.instance
      .getHttpsCallable(functionName: "createNotification");
  fields['to'] = uid;
  await post.call({"to": uid, "notification": fields}).catchError((error) {
    print(error);
  });
}

Future<User> getUserFromUID(String uid) async {
  DocumentSnapshot snap = await Firestore.instance.document('users/$uid').get();
  globals.reads++;
  if(uid == null) {
    return null;
  }
  return User(
      displayName: snap.data["display"],
      imageUrl: snap.data["image"],
      uid: uid);
}

visitUserPage(String uid, BuildContext context) async {
  Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              Scaffold(appBar: AppBar(), body: ProfilePage(uid))));
}
