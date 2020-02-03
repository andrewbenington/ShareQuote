import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Home/NotificationsPage.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;

StreamSubscription iosSubscription;

class NotificationHandler extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _NotificationHandlerState();
  }
}

class _NotificationHandlerState extends State<NotificationHandler> {
  final FirebaseMessaging _fcm = FirebaseMessaging();
  String message = "";
  @override
  void initState() {
    super.initState();

    if (Platform.isIOS) {
      iosSubscription = _fcm.onIosSettingsRegistered.listen((data) {
        saveToken();
      });

      try {
        _fcm.requestNotificationPermissions(IosNotificationSettings());
      } catch (error) {
        print(error);
      }
    } else {
      saveToken();
    }
    _fcm.configure(onMessage: (Map<String, dynamic> message) async {
      print("onMessage: $message");
      SnackBar snackBar = SnackBar(
        content:
            Text(message == null ? "null" : message['notification']['body']),
      );
      Scaffold.of(context).showSnackBar(snackBar);
    }, onLaunch: (Map<String, dynamic> message) async {
      print("onLaunch: $message");
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => NotificationsPage()));
      // TODO optional
    }, onResume: (Map<String, dynamic> message) async {
      print("onResume: $message");
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => NotificationsPage()));
      // TODO optional
    });
  }

  void saveToken() async {
    String token = await _fcm.getToken();
    Firestore.instance
        .document('users_private/${globals.firebaseUser.uid}')
        .setData({"token": token}, merge: true);
    print("InstanceID: $token");
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
