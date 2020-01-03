import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Awards/AwardsStream.dart';
import 'package:pearawards/Utils/Upload.dart';
import 'Collection.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;

import 'package:pearawards/Utils/CustomPainters.dart';

import 'NewCollection.dart';

int currentIndex = 0;

String awardTitle = "";
List<Collection> collections;
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

  bool mostRecent = true;
  String errorMessage = "";
  @override
  void initState() {
    super.initState();
      loadCollections(widget.url);
    
  }

  loadCollections(String url) async {
    loading = true;
    var coll = Firestore.instance
        .collection('users/' + globals.firebaseUser.uid + '/collections');

    collections = await coll.getDocuments().then((colls) {
      return colls.documents.map((document) {
        if (globals.loadedCollections[document.documentID] == null) {
          if (document.data["isPointer"]) {
            loadFriendCollection(document.reference);
          } else {
            globals.loadedCollections[document.documentID] = Collection(
                docRef: document.reference,
                title: document.data["name"],
                owner: document.data["owner"],);
          }
        }
        return globals.loadedCollections[document.documentID];
      }).toList();
    });
    if (coll == null) {
      error = true;
    }
    loading = false;

    if (mounted) {
      setState(() {});
    }
  }

  loadFriendCollection(DocumentReference reference) async {
    DocumentSnapshot document = await reference.get();
    globals.loadedCollections[document.documentID] = Collection(
        docRef: document.reference,
        title: document.data["name"],
        owner: document.data["owner"]);
  }

  @override
  Widget build(BuildContext context) {
    if (collections == null && !loading && !error) {
      loadCollections(widget.url);
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
                      loadCollections(widget.url);
                    },
                  ),
                  Spacer()
                ])
              : collections != null && loading == false
                  ? RefreshIndicator(
                      backgroundColor: Colors.white,
                      // backgroundColor: _user == null
                      //     ? Theme.of(context).primaryColor
                      //     : colorFromID(_user.id),
                      child: buildGrid(),
                      onRefresh: () async {
                        loadCollections(widget.url);
                        return;
                      },
                    )
                  : CircularProgressIndicator()),
    );
  }

  Widget buildGrid() {
    return GridView.builder(
      itemCount: collections.length + 1,
      itemBuilder: (BuildContext context, int index) {
        return index == collections.length
            ? GridTile(child: buildNewCollectionButton())
            : GridTile(child: CollectionTile(c: collections[index]));
      },
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200.0,
      ),
    );
  }

  Widget buildNewCollectionButton() {
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
                            decoration:
                                InputDecoration(hintText: "Collection name"),
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
                          createCollection(
                              globals.firebaseUser, name_controller.text);
                          setState(() {});
                          Navigator.of(context).pop();
                        },
                      )
                    ],
                  );
                });
          },
        ));
  }
}

class CollectionTile extends StatelessWidget {
  CollectionTile({this.c});
  Collection c;
  String label = "";

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      child: CustomPaint(
        painter: CornersPainter(),
        child: FlatButton(
          onPressed: () {
            Navigator.push(
              context,
              growRoute(c),
            );
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
}

Route growRoute(Collection c) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => AwardsStream(
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
