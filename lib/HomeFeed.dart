import 'dart:io';
import 'dart:isolate';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:pearawards/AwardPage.dart';
import 'package:pearawards/Converter.dart';
import 'package:pearawards/Upload.dart';
import 'Globals.dart' as globals;

import 'Award.dart';
import 'HomePage.dart';
import 'echo.dart';

int currentIndex = 0;

StreamBuilder<QuerySnapshot> awards;

bool error = false;
bool loading = false;
bool mostRecent = true;

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
  void setMostRecent(bool setto) {
    mostRecent = setto;
  }

  void setSearchText(String search) {
    searchText = search;
    createState();
  }

  String getTitle() {
    return awardTitle;
  }
}

class _HomeFeedState extends State<HomeFeed> {
  TextEditingController search_controller = TextEditingController();
  TextEditingController name_controller = TextEditingController();
  TextEditingController url_controller = TextEditingController();
  bool mostRecent = true;
  String errorMessage = "";
  @override
  void initState() {
    super.initState();
  }

  StreamBuilder<QuerySnapshot> awardStream(DocumentReference document) {
    return StreamBuilder<QuerySnapshot>(
      stream: document.collection("awards").orderBy("timestamp",descending: true).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return new Text('Loading...');
          default:
            return ListView(
                children:
                    snapshot.data.documents.map((DocumentSnapshot document) {
              Map json = jsonDecode(document.data["json"]);
              return buildAwardCard(context, Award.fromJson(json), true);
            }).toList());
        }
      },
    );
  }

  loadAwardsFromDoc(String url) async {
    loading = true;
    Result result = await retrieveAwards(url);
    if (!result.success) {
      error = true;
      errorMessage = result.error;
    } else {
      error = false;
      //awards = result.awards;
      awardTitle = result.title;
    }

    loading = false;
    if (awards == null) {
      error = true;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    /*if (awards == null && !loading && !error ||
        awards != null && awards.length == 0) {
      loadAwards(widget.url);
    }*/
    return Scaffold(
      
      backgroundColor: Colors.green[200],
      body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: error
              ? Column(children: <Widget>[
                  Spacer(),
                  Text(errorMessage),
                  RaisedButton(
                    child: Text("Try again"),
                    onPressed: () {
                      
                    },
                  ),
                  Spacer()
                ])
              : awards != null && loading == false
                  ? RefreshIndicator(
                      backgroundColor: Colors.white,
                      // backgroundColor: _user == null
                      //     ? Theme.of(context).primaryColor
                      //     : colorFromID(_user.id),
                      //child: awardStream(widget.document),
                      onRefresh: () async {
                        //awardStream(widget.document);
                        return;
                      },
                    )
                  : CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //UploadDoc(auth.firebaseUser, Document(name: awardTitle, awards: awards));
        },
        tooltip: 'Increment',
        child: Icon(Icons.check),
      ),
    );
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold();
  }

  /*ListView buildList() {
    var list = ListView.builder(
      controller: ScrollController(),
      itemCount: awards.length,
      itemBuilder: (BuildContext context, int index) {
        if (mostRecent) {
          index = awards.length - index - 1;
        }
        return HomeFeed.searchText == null || HomeFeed.searchText == ""
            ? buildAwardCard(context, awards[index], true)
            : awards[index].contains(HomeFeed.searchText)
                ? buildAwardCard(context, awards[index], true)
                : new Container();
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      list.controller.jumpTo(0);
    });

    return list;
  }*/
}
