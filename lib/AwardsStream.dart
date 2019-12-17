import 'dart:io';
import 'dart:isolate';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:pearawards/AwardPage.dart';
import 'package:pearawards/CollectionPage.dart';
import 'package:pearawards/Converter.dart';
import 'package:pearawards/Upload.dart';
import 'Auth.dart' as auth;

import 'Award.dart';
import 'HomePage.dart';
import 'echo.dart';

int currentIndex = 0;

List<Award> awards;

bool error = false;
bool loading = false;
bool mostRecent = true;

class AwardsStream extends StatefulWidget {
  static String searchText;
  AwardsStream({Key key, this.document, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final DocumentReference document;
  final String title;

  @override
  _AwardsStreamState createState() => _AwardsStreamState();
  void setMostRecent(bool setto) {
    mostRecent = setto;
  }

  void setSearchText(String search) {
    searchText = search;
    createState();
  }

  String getTitle() {
    return title;
  }
}

class _AwardsStreamState extends State<AwardsStream> {
  TextEditingController search_controller = TextEditingController();
  TextEditingController name_controller = TextEditingController();
  TextEditingController url_controller = TextEditingController();
  bool mostRecent = true;
  String errorMessage = "";
  @override
  void initState() {
    super.initState();
    awards = [];
    loading = true;
    loadAwards();
  }

  loadAwards() async {
    setState(() {
      loading = true;
    });

    QuerySnapshot snapshot = await widget.document
        .collection("awards")
        .orderBy("timestamp", descending: true)
        .getDocuments();

    awards = snapshot.documents.map((doc) {
      var award = Award.fromJson(jsonDecode(doc.data["json"]));
      award.likes = doc.data["likes"];
      return award;
    }).toList();
    setState(() {
      loading = false;
    });
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
      //awardTitle = result.title;
    }

    loading = false;
    if (awards == null) {
      error = true;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (awards == null && !loading && !error) {
      loadAwards();
    }
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.cloud_upload, size: 30),
              onPressed: () {
                setState(() {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Add new document'),
                          content: Container(
                            height: MediaQuery.of(context).size.height * 0.13,
                            child: Column(
                              children: <TextField>[
                                TextField(
                                  controller: url_controller,
                                  decoration: InputDecoration(
                                      hintText: "Google Docs url"),
                                ),
                              ],
                            ),
                          ),
                          actions: <Widget>[
                            new FlatButton(
                              child: new Text('CANCEL'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            new FlatButton(
                              child: new Text('ADD'),
                              onPressed: () {
                                UploadDoc(auth.firebaseUser,
                                    url_controller.text, widget.title);
                                setState(() {});
                                loading = true;
                                Navigator.of(context).pop();
                              },
                            )
                          ],
                        );
                      });
                });
              }),
        ],
        leading: IconButton(
          icon: Icon(Icons.close, size: 30),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        title: Text(widget.title),
      ),
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
                      loadAwards();
                    },
                  ),
                  Spacer()
                ])
              : awards != null && loading == false
                  ? awards.length > 0
                      ? RefreshIndicator(
                          backgroundColor: Colors.white,
                          // backgroundColor: _user == null
                          //     ? Theme.of(context).primaryColor
                          //     : colorFromID(_user.id),
                          child: ListView(
                            children: awards
                                .map((a) => buildAwardCard(context, a, true))
                                .toList(),
                          ),
                          onRefresh: () async {
                            loadAwards();
                            return;
                          },
                        )
                      : Column(
                          children: <Widget>[
                            Spacer(),
                            Text("No Awards", style: TextStyle(color: Colors.green[800], fontSize: 40, fontWeight: FontWeight.bold),),
                            Text("Tap the '+' button to create one!",style: TextStyle(color: Colors.green[800], fontSize: 20,),),
                            Spacer()
                          ],
                        )
                  : CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //UploadDoc(auth.firebaseUser, Document(name: awardTitle, awards: awards));
        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
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
        return AwardsStream.searchText == null || AwardsStream.searchText == ""
            ? buildAwardCard(context, awards[index], true)
            : awards[index].contains(AwardsStream.searchText)
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
