import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/App/HomePage.dart';
import 'package:pearawards/App/LoginPage.dart';
import 'package:pearawards/Notifications/NotificationHandler.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;

NotificationHandler notifications;

void main() async {
  var _auth = FirebaseAuth.instance;
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    theme: ThemeData(primarySwatch: Colors.green),
    title: "FriendAwards",
    home: await getLandingPage(_auth),
  ));
}

Future<Widget> getLandingPage(FirebaseAuth auth) async {
  globals.firebaseUser = await auth.currentUser();
  globals.firebaseAuth = auth;
  return StreamBuilder<FirebaseUser>(
    stream: auth.onAuthStateChanged,
    builder: (BuildContext context, snapshot) {
      if (snapshot.hasData && (!snapshot.data.isAnonymous)) {
        return HomePage();
      }

      return LoginPage();
    },
  );
}
