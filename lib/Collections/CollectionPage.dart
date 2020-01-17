import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'Collection.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;

import 'package:pearawards/Utils/CustomPainters.dart';

import 'CollectionStream.dart';
import 'package:pearawards/Collections/CollectionFunctions.dart';

int currentIndex = 0;

String awardTitle = "";
int length;

bool error = false;
bool loading = false;
bool mostRecent = true;

String searchText;

class CollectionPage extends StatefulWidget {
  CollectionPage({Key key, this.url, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String url;
  final String title;

  @override
  _CollectionPageState createState() => _CollectionPageState();
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

class _CollectionPageState extends State<CollectionPage> {
  TextEditingController name_controller = TextEditingController();
  bool load = false;

  bool mostRecent = true;
  String errorMessage = "";
  @override
  void initState() {
    super.initState();
    loadCollections();
  }

  loadCollections() async {
    loading = true;
    var coll = Firestore.instance
        .collection('users/${globals.firebaseUser.uid}/collections');

    coll.getDocuments().then((colls) {
      for (DocumentSnapshot document in colls.documents) {
        loadCollectionFromReference(
            document.data["reference"], document.reference);
      }
      if (coll == null) {
        error = true;
      }
      loading = false;

      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (load || (globals.loadedCollections == null && !loading && !error)) {
      loadCollections();
    }
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
                      loadCollections();
                    },
                  ),
                  Spacer()
                ])
              : globals.loadedCollections != null && loading == false
                  ? RefreshIndicator(
                      backgroundColor: Colors.white,
                      // backgroundColor: _user == null
                      //     ? Theme.of(context).primaryColor
                      //     : colorFromID(_user.id),
                      child: buildGrid(),
                      onRefresh: () async {
                        loadCollections();
                        return;
                      },
                    )
                  : CircularProgressIndicator()),
    );
  }

  Widget buildGrid() {
    return GridView.builder(
      itemCount: globals.loadedCollections.length + 1,
      itemBuilder: (BuildContext context, int index) {
        List<Collection> sortedCollections =
            globals.loadedCollections.values.toList();
        sortedCollections.sort((col1, col2) {
          return col2.lastEdited - col1.lastEdited;
        });
        return index == globals.loadedCollections.length
            ? GridTile(child: buildNewCollectionButton())
            : GridTile(
                child: CollectionTile(
                    c: sortedCollections[index],
                    onChanged: () {
                      loadCollections();
                    }));
      },
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300.0,
      ),
    );
  }

  Widget buildNewCollectionButton() {
    name_controller.clear();
    return Padding(
        padding: EdgeInsets.all(60),
        child: FlatButton(
          shape: CircleBorder(),
          child: Icon(
            Icons.add,
            size: 40,
            color: Colors.green,
          ),
          color: HSLColor.fromAHSL(0.6, 0, 0, 1).toColor(),
          onPressed: () {
            showCollectionDialog();
          },
        ));
  }

  void showCollectionDialog() async {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Add new collection'),
            content: Container(
              height: MediaQuery.of(context).size.height * 0.13,
              child: Column(
                children: <TextField>[
                  TextField(
                    controller: name_controller,
                    decoration: InputDecoration(hintText: "Collection name"),
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
                  Navigator.of(context).pop();
                  createAndUpdate(globals.firebaseUser, name_controller.text);
                },
              )
            ],
          );
        });
  }

  createAndUpdate(FirebaseUser user, String title) async {
    print(await createCollection(user, title));
    load = true;

    loadCollections();
  }
}

class CollectionTile extends StatelessWidget {
  CollectionTile({this.c, this.onChanged});
  Collection c;
  Function onChanged;
  String label = "";

  @override
  Widget build(BuildContext context) {
    if (c == null) {
      int i = 0;
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      child: CustomPaint(
        painter: CornersPainter(),
        child: FlatButton(
          onPressed: () {
            pushCollectionStream(context, c, onChanged);
          },
          child: Text(
            c.title,
            style: TextStyle(fontSize: 28),
          ),
        ),
      ),
      margin: EdgeInsets.all(10),
    );
  }

  pushCollectionStream(
      BuildContext context, Collection c, Function onChanged) async {
    if (await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CollectionStream(
          collectionInfo: c,
          title: c.title,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
              scale: animation.drive(CurveTween(curve: Curves.ease)),
              alignment: Alignment.center,
              child: child);
        },
      ),
    )) {
      onChanged();
    }
  }
}

Route growRoute(Collection c) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => CollectionStream(
      collectionInfo: c,
      title: c.title,
    ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
          scale: animation.drive(CurveTween(curve: Curves.ease)),
          alignment: Alignment.center,
          child: child);
    },
  );
}
