import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'package:pearawards/Converter.dart';
import 'package:pearawards/Upload.dart';
import 'AddQuote.dart';
import 'Globals.dart' as globals;

import 'Award.dart';
import 'Collection.dart';

int currentIndex = 0;

class AwardsStream extends StatefulWidget {
  static String searchText;
  AwardsStream({Key key, this.collectionInfo, this.title}) : super(key: key) {
    setTitle();
  }

  void setTitle() async {
    title = await collectionInfo.docRef.get().then((doc) {
      return doc.documentID;
    });
  }

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final Collection collectionInfo;
  String title;

  @override
  _AwardsStreamState createState() => _AwardsStreamState();

  String getTitle() {
    return title;
  }
}

class _AwardsStreamState extends State<AwardsStream> {
  TextEditingController search_controller = TextEditingController();
  TextEditingController name_controller = TextEditingController();
  TextEditingController url_controller = TextEditingController();
  bool error = false;
  bool loading = false;
  bool mostRecent = true;
  bool auditing = false;
  List<Award> awards;

  String errorMessage = "";
  @override
  void initState() {
    super.initState();
    awards = widget.collectionInfo.awards;
    loading = true;
    refresh();
  }

  addGoogleDoc() async {
    setState(() {
      loading = true;
    });
    await uploadDoc(globals.firebaseUser, url_controller.text, widget.title);
    await loadAwards();
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  refresh() async {
    await loadAwards();
    await auditDocument();
    await loadAwards();
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  loadAwards() async {
    if (widget.collectionInfo.lastLoaded >=
        (await widget.collectionInfo.docRef.get()).data["lastEdit"]) {
      if (awards.length == 0) {
        awards = widget.collectionInfo.awards;
      }
      return;
    }
    QuerySnapshot snapshot = await widget.collectionInfo.docRef
        .collection("awards")
        .orderBy("timestamp", descending: true)
        .getDocuments();

    awards = snapshot.documents.map((doc) {
      var award = Award.fromJson(jsonDecode(doc.data["json"]));
      award.likes = doc.data["likes"];
      award.docRef = doc.reference;
      award.timestamp = doc.data["timestamp"];
      return award;
    }).toList();
    widget.collectionInfo.awards = awards;
    widget.collectionInfo.lastLoaded = DateTime.now().microsecondsSinceEpoch;
  }

  @override
  Widget build(BuildContext context) {
    if (awards == null && !loading && !error) {
      refresh();
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
                                addGoogleDoc();
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
                      refresh();
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
                          onRefresh: () => refresh(),
                        )
                      : Column(
                          children: <Widget>[
                            Spacer(),
                            Text(
                              "No Awards",
                              style: TextStyle(
                                  color: Colors.green[800],
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Tap the '+' button to create one!",
                              style: TextStyle(
                                color: Colors.green[800],
                                fontSize: 20,
                              ),
                            ),
                            Spacer()
                          ],
                        )
                  : CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          newAward();
        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> auditDocument() async {
    if (auditing) {
      return;
    }
    auditing = true;
    Map collection = (await widget.collectionInfo.docRef.get()).data;
    String url = collection["googledoc"];

    if (url == null) {
      return;
    }
    Result result = await retrieveAwards(url);
    Map<int, Award> inServer = Map();
    awards.forEach((a) {
      if (a.fromDoc) {
        if (inServer[a.hash] != null) {
          a.docRef.delete();
        } else {
          inServer[a.hash] = a;
        }
      }
    });
    Map<int, Award> inDoc = Map();
    result.awards.forEach((a) {
      if (a.fromDoc) {
        if (inServer[a.hash] == null) {
          inDoc[a.hash] = a;
        } else {
          inServer.remove(a.hash);
        }
      }
    });
    if (inServer.length > 0) {
      widget.collectionInfo.docRef
          .updateData({"lastEdit": DateTime.now().microsecondsSinceEpoch});
    }
    inServer.forEach((sHash, sAward) {
      sAward.docRef.delete();
    });
    inDoc.forEach((dHash, dAward) {
      uploadNewAward(globals.firebaseUser, dAward, widget.title);
    });
    auditing = false;
  }

  newAward() async {
    bool another = await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => AddQuote(
            title: widget.title,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
                scale: animation.drive(CurveTween(curve: Curves.ease)),
                alignment: Alignment.center,
                child: child);
          },
        ));
    if (another) {
      loading = true;
      await refresh();
      loading = false;
    }
  }
}
