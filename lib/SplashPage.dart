import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;
import 'package:pearawards/Utils/Utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'App/HomePage.dart';
import 'App/LoginPage.dart';

class SplashPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    getLandingPage(FirebaseAuth.instance, context);
    return Scaffold(
      backgroundColor: globals.theme == null
          ? globals.themes["Moss"].backTextColor
          : globals.theme.backgroundColor,
      body: Column(
        children: <Widget>[
          Spacer(),
          Row(
            children: <Widget>[
              Spacer(),
              Text(
                "Share",
                style: TextStyle(
                    fontSize: 52.0, color: globals.theme.backTextColor),
              ),
              Text(
                "Quote",
                style: TextStyle(
                    fontSize: 52.0,
                    fontWeight: FontWeight.bold,
                    color: globals.theme.darkPrimary),
              ),
              Spacer(),
            ],
          ),
          Spacer()
        ],
      ),
    );
  }
}

getLandingPage(FirebaseAuth auth, BuildContext context) async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  print("build ${packageInfo.buildNumber}");
  /*List<String> versionParts = packageInfo.buildNumber.split(".");
  bool valid = true;
  Map mostUpdated =
      (await Firestore.instance.document('info/versions').get()).data;
  List<String> updatedParts;
  if (Platform.isIOS) {
    updatedParts = mostUpdated["ios"].split(".");
  } else if (Platform.isAndroid) {
    updatedParts = mostUpdated["android"].split(".");
  }
  for (int i = 0; i < versionParts.length; i++) {
    if (int.parse(versionParts[i]) > int.parse(updatedParts[i])) {
      break;
    }
    if (int.parse(versionParts[i]) < int.parse(updatedParts[i])) {
      valid = false;
      break;
    }
  }
  if (!valid) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Container(
              child: Text("Please update to the latest version."),
            ),
          );
        });
    return;
  }*/

  SharedPreferences prefs = await SharedPreferences.getInstance();
  globals.firebaseAuth = auth;
  globals.firebaseUser = await auth.currentUser();
  if (globals.firebaseUser != null) {
    globals.me = await getUserFromUID(globals.firebaseUser.uid);
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => HomePage()));
    return Container();
  } else {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginPage()));
  }
}
