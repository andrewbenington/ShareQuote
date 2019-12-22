import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'package:pearawards/Converter.dart';
import 'package:pearawards/Upload.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    if (widget.collectionInfo.loaded) {
      awards = widget.collectionInfo.awards;
      loadAwards();
    } else {
      attemptLoadAwards();
    }
  }

  attemptLoadAwards() async {
    loading = true;
    final prefs = (await SharedPreferences.getInstance());
    String jsonString =
        prefs.getString(widget.collectionInfo.docRef.documentID);

    if (jsonString != null) {
      print("stored");
      Map json = jsonDecode(jsonString);
      List<Award> loadedAwards = [];
      for (Map m in json["awards"]) {
        loadedAwards.add(Award.fromJson(m));
      }
      widget.collectionInfo.awards = loadedAwards;
      widget.collectionInfo.loaded = true;
      widget.collectionInfo.lastLoaded = json["lastLoaded"];
    }
    refresh();
  }

  deleteCollection() async {
    await deleteAwardsFromMemory();
    awards = [];
    globals.loadedCollections.remove(widget.collectionInfo.docRef.documentID);
    widget.collectionInfo.docRef
        .collection('awards')
        .getDocuments()
        .then((snapshot) {
      for (DocumentSnapshot ds in snapshot.documents) {
        ds.reference.delete();
      }
    });
    widget.collectionInfo.docRef.delete();
    Navigator.pop(context);
    Navigator.pop(context);
  }

  deleteAwardsFromMemory() async {
    final prefs = (await SharedPreferences.getInstance());
    prefs.remove(widget.collectionInfo.docRef.documentID);
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
        auditing = false;
      });
    }
  }

  loadAwards() async {
    int thisDevice = widget.collectionInfo.lastLoaded;
    int server = (await widget.collectionInfo.docRef.get()).data["lastEdit"];
    if (thisDevice >= server) {
      if (awards == null || awards.length == 0) {
        awards = widget.collectionInfo.awards;
      }
      return;
    }
    print("reloaded all awards");
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
    storeAwards();
  }

  storeAwards() async {
    widget.collectionInfo.awards = awards;
    widget.collectionInfo.loaded = true;
    widget.collectionInfo.lastLoaded = DateTime.now().microsecondsSinceEpoch;
    final prefs = await SharedPreferences.getInstance();
    List<Map> amaps = [];
    for (Award a in widget.collectionInfo.awards) {
      amaps.add(awardToJson(a));
    }
    prefs.setString(
        widget.collectionInfo.docRef.documentID,
        jsonEncode(
            {"awards": amaps, "lastLoaded": widget.collectionInfo.lastLoaded}));
  }

  @override
  Widget build(BuildContext context) {
    if (awards == null && !loading && !error) {
      refresh();
    }
    return Scaffold(
      endDrawer: buildDrawer(),
      appBar: AppBar(
        actions: <Widget>[],
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
                            children: mostRecent
                                ? awards
                                    .map(
                                        (a) => buildAwardCard(context, a, true))
                                    .toList()
                                : awards
                                    .map(
                                        (a) => buildAwardCard(context, a, true))
                                    .toList()
                                    .reversed
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
    if (inServer.length > 0 || inDoc.length > 0) {
      widget.collectionInfo.docRef
          .updateData({"lastEdit": DateTime.now().microsecondsSinceEpoch});
    }

    inDoc.forEach((dHash, dAward) {
      dAward.showYear = false;
      uploadNewAward(
          globals.firebaseUser, dAward, widget.title, inServer[dHash] == null);
    });
    inServer.forEach((sHash, sAward) {
      sAward.docRef.delete();
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

  Drawer buildDrawer() {
    return Drawer(
      child: Column(
        children: <Widget>[
          AppBar(
            backgroundColor: Colors.green,
            title: Text("Options"),
          ),
          Container(
            child: Row(
              children: <Widget>[
                Text("Order: "),
                Expanded(
                  child: ChoiceChip(
                    labelStyle: TextStyle(
                        color: mostRecent ? Colors.green : Colors.black87),
                    label: Text('Latest'),
                    onSelected: (bool selected) {
                      setState(() {
                        mostRecent = selected;
                      });
                    },
                    selected: mostRecent,
                  ),
                ),
                Expanded(
                  child: ChoiceChip(
                    label: Text('First'),
                    onSelected: (bool selected) {
                      setState(() {
                        mostRecent = !selected;
                      });
                    },
                    selected: !mostRecent,
                  ),
                ),
              ],
            ),
            margin: EdgeInsets.all(10.0),
          ),
          /*Container(
            height: MediaQuery.of(context).size.height * 0.7,
            child: ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  key: ObjectKey(documents[index]),
                  child: RaisedButton(
                    child: Text(documents[index].name),
                    onPressed: () {
                      pageIndex = index;
                      setState(() {
                        stream = AwardsStream(
                          url: documents[index].url,
                          title: documents[index].name,
                        );
                        Navigator.of(context).pop();
                      });
                    },
                  ),
                  onDismissed: (direction) {
                    Document temp = documents[index];
                    documents.removeAt(index);
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Document deleted'),
                            actions: <Widget>[
                              new FlatButton(
                                child: new Text('UNDO'),
                                onPressed: () {
                                  documents.insert(index, temp);
                                  Navigator.of(context).pop();
                                },
                              ),
                              new FlatButton(
                                child: new Text('OK'),
                                onPressed: () {
                                  setState(() {});
                                  Navigator.of(context).pop();
                                },
                              )
                            ],
                          );
                        });
                  },
                );
              },
            ),
          ),*/
          IconButton(
              icon: Icon(Icons.cloud_upload, size: 30), onPressed: () {}),
          RaisedButton(
            child: Text("New Document"),
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
            },
          ),
          RaisedButton(
              child: Text("Delete Document"), onPressed: deleteCollection)
        ],
      ),
    );
  }
}
