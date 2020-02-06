import 'package:flutter/material.dart';
import 'package:pearawards/Notifications/NotificationHandler.dart';
import 'package:pearawards/SplashPage.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;
import 'package:shared_preferences/shared_preferences.dart';

NotificationHandler notifications;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String theme = prefs.getString('theme');
  if (theme == null || globals.themes[theme] == null) {
    globals.changeTheme("Moss");
  } else {
    globals.changeTheme(theme);
  }
  runApp(ShareQuote());
}

class ShareQuote extends StatefulWidget {
  ShareQuote();
  @override
  State<StatefulWidget> createState() {
    return ShareQuoteState();
  }
}

class ShareQuoteState extends State<StatefulWidget> {
  ThemeData theme = globals.themeData;
  updateTheme() {
    theme = globals.themeData;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    globals.updateTheme = updateTheme;
    return MaterialApp(
      theme: globals.themeData,
      title: "FriendAwards",
      home: SplashPage(),
    );
  }
}
