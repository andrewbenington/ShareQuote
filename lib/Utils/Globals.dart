library sharequote.globals;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Awards/Award.dart';

import 'package:pearawards/Collections/Collection.dart';
import 'package:pearawards/Profile/User.dart';
import 'package:pearawards/main.dart';

class MyTheme {
  MyTheme(
      {this.primaryColor,
      this.textColor,
      this.backgroundColor,
      this.darkPrimary,
      this.greyPrimary,
      this.lightPrimary,
      this.cardColor,
      this.buttonColor,
      this.backTextColor});
  Color textColor;
  Color buttonColor;
  Color primaryColor;
  Color backgroundColor;
  Color darkPrimary;
  Color greyPrimary;
  Color lightPrimary;
  Color cardColor;
  Color backTextColor;
}

FirebaseAuth firebaseAuth;
FirebaseUser firebaseUser;

Map<String, Collection> loadedCollections = Map();
Map<String, User> loadedUsers = Map();
Map<String, Award> loadedAwards = Map();
Map<String, bool> likeRequests = Map();
Map<String, bool> followRequests = Map();
List<Widget> pages = [];
List<Widget> profileTabPages = [];
int profileIndex = 0;
MyTheme theme = themes["green"];
ThemeData themeData =
    ThemeData(primaryColor: Colors.green, primarySwatch: Colors.green);
Function updateTheme = () {};
int reads = 0;
User me = User();

String myName = "";

Color primaryColor;
Map<String, MyTheme> themes = {
  "Moss": MyTheme(
      primaryColor: Colors.green,
      lightPrimary: Colors.green[400],
      backgroundColor: Colors.green[200],
      cardColor: Colors.white,
      textColor: Colors.black,
      darkPrimary: Colors.green[800],
      buttonColor: Colors.green,
      backTextColor: Colors.green[800]),
  "Night": MyTheme(
      primaryColor: Colors.blueGrey,
      lightPrimary: Colors.blueGrey[400],
      backgroundColor: Colors.blueGrey[900],
      textColor: Colors.white,
      cardColor: Colors.blueGrey[800],
      darkPrimary: Colors.black45,
      buttonColor: Colors.white,
      backTextColor: Colors.white),
  "Strawberry": MyTheme(
      primaryColor: Colors.red[700],
      lightPrimary: Colors.red[300],
      backgroundColor: Colors.red[200],
      textColor: Colors.black87,
      cardColor: Colors.white,
      darkPrimary: Colors.red[800],
      buttonColor: Colors.red,
      backTextColor: Colors.red[600]),
  "Grape": MyTheme(
      primaryColor: Colors.deepPurple,
      lightPrimary: Colors.deepPurple[400],
      backgroundColor: Colors.deepPurple[200],
      textColor: Colors.black87,
      cardColor: Colors.white,
      darkPrimary: Colors.deepPurple[800],
      buttonColor: Colors.deepPurple,
      backTextColor: Colors.deepPurple),
  "Grapefruit": MyTheme(
      primaryColor: Colors.deepOrange[700],
      lightPrimary: Colors.deepOrange[400],
      backgroundColor: Colors.deepOrange[200],
      textColor: Colors.black87,
      cardColor: Colors.white,
      darkPrimary: Colors.deepOrange[800],
      buttonColor: Colors.deepOrange,
      backTextColor: Colors.deepOrange[600]),
  "Don't Talk To Me Till I've Had My Coffee": MyTheme(
      primaryColor: Colors.brown[700],
      lightPrimary: Colors.brown[400],
      backgroundColor: Colors.brown[200],
      textColor: Colors.black87,
      cardColor: Colors.white,
      darkPrimary: Colors.brown[800],
      buttonColor: Colors.brown,
      backTextColor: Colors.brown[600]),
  "Blüu": MyTheme(
      primaryColor: Colors.blue[700],
      lightPrimary: Colors.blue[400],
      backgroundColor: Colors.blue[200],
      textColor: Colors.black87,
      cardColor: Colors.white,
      darkPrimary: Colors.blue[800],
      buttonColor: Colors.blue,
      backTextColor: Colors.blue[600]),
};

loadUser(String uid) async {
  if (loadedUsers.containsKey(uid)) {
    return;
  }
  loadedUsers[uid] = null;
  DocumentSnapshot userSnapshot =
      (await Firestore.instance.document('users/$uid').get());
      reads++;
  loadedUsers[uid] = User(
      displayName: userSnapshot.data["display"],
      uid: uid,
      imageUrl: userSnapshot.data["image"]);
  loadedUsers[uid].lastUpdated = DateTime.now().microsecondsSinceEpoch;
}

changeTheme(String newTheme, BuildContext context) {
  if (themes[newTheme] == null) {
    theme = themes["Moss"];
    themeData =
        ThemeData(primaryColor: Colors.green, primarySwatch: Colors.green);
  } else {
    theme = themes[newTheme];
    Map<int, Color> matcolor = {
      50: theme.primaryColor.withOpacity(.1),
      100: theme.primaryColor.withOpacity(.2),
      200: theme.primaryColor.withOpacity(.3),
      300: theme.primaryColor.withOpacity(.4),
      400: theme.primaryColor.withOpacity(.5),
      500: theme.primaryColor.withOpacity(.6),
      600: theme.primaryColor.withOpacity(.7),
      700: theme.primaryColor.withOpacity(.8),
      800: theme.primaryColor.withOpacity(.9),
      900: theme.primaryColor.withOpacity(1),
    };
    themeData = ThemeData(
      fontFamily: context ==null ? "Helvetica" : DefaultTextStyle.of(context).style.fontFamily,
        primaryColor: theme.primaryColor,
        primarySwatch: MaterialColor(
            theme.primaryColor.red * 65536 +
                theme.primaryColor.green * 256 +
                theme.primaryColor.blue,
            matcolor));
  }
  if (updateTheme != null) {
    updateTheme();
  }
}
