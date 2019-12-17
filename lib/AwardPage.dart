import 'package:flutter/material.dart';
import 'package:pearawards/Converter.dart';
import 'package:pearawards/AwardsStream.dart';

import 'Award.dart';

class AwardPage extends StatefulWidget {
  AwardPage({Key key, this.award, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final Award award;
  final String title;

  @override
  _AwardPageState createState() => _AwardPageState();
}

class _AwardPageState extends State<AwardPage> {
  _AwardPageState();
  bool mostRecent = true;

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: ListView(
        children: <Widget>[
          buildAwardCard(context, widget.award, false),
        ],
      ),
      backgroundColor: Colors.green[200],
    );
  }
}
