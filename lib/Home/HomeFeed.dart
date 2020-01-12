import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pearawards/Awards/AddQuote.dart';
import 'package:pearawards/Awards/AwardsStream.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Utils/Converter.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;
import 'package:pearawards/Utils/Utils.dart';

class HomeFeed extends StatefulWidget {
  static String searchText;

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  _HomeFeedState createState() => _HomeFeedState();

  void setSearchText(String search) {
    searchText = search;
    createState();
  }

  String getTitle() {
    return awardTitle;
  }
}

class _HomeFeedState extends State<HomeFeed> {
  bool mostRecent = true;
  String errorMessage = "";
  PrimitiveWrapper shouldLoad = PrimitiveWrapper(false);
  PrimitiveWrapper isLoading = PrimitiveWrapper(false);
  final PrimitiveWrapper noAwards = PrimitiveWrapper(false);

  @override
  void initState() {
    super.initState();
  }

  Future<void> refresh() async {
    shouldLoad.value = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[200],
      body: Stack(children: <Widget>[
        Center(
          child: RefreshIndicator(
            child: noAwards.value && !isLoading.value
                ? ListView(children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          Text(
                            'No Awards',
                            style: TextStyle(
                                color: Colors.green[800],
                                fontSize: 40,
                                fontWeight: FontWeight.bold),
                          )
                        ]))
                  ])
                : CustomScrollView(slivers: <Widget>[
                    AwardsStream(
                      docRef: Firestore.instance
                          .document('users/${globals.firebaseUser.uid}'),
                      directoryName: 'feed',
                      shouldLoad: shouldLoad,
                      refreshParent: () {
                        setState(() {});
                      },
                      isLoading: isLoading,
                      noAwards: noAwards,
                    ),
                  ]),
            onRefresh: refresh,
          ),
        ),
        Container(
          child: isLoading.value
              ? Center(child: CircularProgressIndicator())
              : null,
          constraints: BoxConstraints.expand(),
        )
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          newAward();
        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }

  newAward() async {
    bool another = await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => AddQuote(
            document: null,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
                scale: animation.drive(CurveTween(curve: Curves.ease)),
                alignment: Alignment.center,
                child: child);
          },
        ));
    if (another) {
      shouldLoad.value = true;
    }
  }
}
