import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Awards/AddQuote.dart';
import 'package:pearawards/Awards/Award.dart';
import 'package:pearawards/Awards/AwardsStream.dart';
import 'package:pearawards/Collections/CollectionFunctions.dart';
import 'package:pearawards/Utils/Converter.dart';
import 'package:pearawards/Utils/Upload.dart';
import 'package:pearawards/Utils/Utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;
import 'package:pearawards/Collections/Collection.dart';

int currentIndex = 0;

class CollectionStream extends StatefulWidget {
  static String searchText;
  CollectionStream({Key key, this.collectionInfo, this.title})
      : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked 'final'.

  final Collection collectionInfo;
  String title;

  @override
  _CollectionStreamState createState() => _CollectionStreamState();

  String getTitle() {
    return title;
  }
}

class _CollectionStreamState extends State<CollectionStream> {
  TextEditingController urlController = TextEditingController();
  bool error = false;
  PrimitiveWrapper shouldLoad = PrimitiveWrapper(false);
  PrimitiveWrapper isLoading = PrimitiveWrapper(false);
  PrimitiveWrapper noAwards = PrimitiveWrapper(false);
  PrimitiveWrapper filter = PrimitiveWrapper(false);
  bool mostRecent = true;
  bool auditing = false;
  bool visibleToPublic = false;
  bool visibleToFriends = false;
  Drawer drawer;
  List<AwardLoader> awards;
  bool updated = false;
  int loaded = 0;
  Function remoteRefresh;

  String errorMessage = '';
  @override
  void initState() {
    drawer = buildDrawer();
    super.initState();
  }

  addGoogleDoc() async {
    await uploadDoc(
        globals.firebaseUser, urlController.text, widget.collectionInfo.docRef);

    if (mounted) {
      setState(() {
        shouldLoad.value = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    drawer = buildDrawer();
    return Scaffold(
      endDrawer: drawer,
      appBar: AppBar(
        actions: [CollectionActions()],
        leading: IconButton(
          icon: Icon(Icons.close, size: 30),
          onPressed: () => Navigator.of(context).pop(updated),
        ),
        title: widget.title == null || widget.title == ''
            ? Container()
            : Container(
                child:
                    FittedBox(fit: BoxFit.scaleDown, child: Text(widget.title)),
                margin: EdgeInsets.only(bottom: 15.0, top: 8.0),
                alignment: Alignment.center,
              ),
      ),
      backgroundColor: Colors.green[200],
      body: RefreshIndicator(
        child: noAwards.value && !isLoading.value && !shouldLoad.value
            ? ListView(children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'No Awards',
                          style: TextStyle(
                              color: Colors.green[800],
                              fontSize: 40,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Tap the \'+\' button to add one!',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ])
            : Stack(children: <Widget>[
                CustomScrollView(slivers: <Widget>[
                  AwardsStream(
                    collectionInfo: widget.collectionInfo,
                    docRef: widget.collectionInfo.docRef,
                    title: widget.collectionInfo.title,
                    shouldLoad: shouldLoad,
                    isLoading: isLoading,
                    noAwards: noAwards,
                    filter: filter,
                    refreshParent: () {
                      setState(() {});
                      rebuildAllChildren(context);
                    },
                  ),
                ]),
                Container(
                  child: isLoading.value
                      ? Center(child: CircularProgressIndicator())
                      : null,
                  constraints: BoxConstraints.expand(),
                )
              ]),
        onRefresh: refresh,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          newAward();
        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> refresh() async {
    shouldLoad.value = true;
    setState(() {});
  }

  newAward() async {
    Award addedAward = await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => AddQuote(
            document: widget.collectionInfo.docRef,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
                scale: animation.drive(CurveTween(curve: Curves.ease)),
                alignment: Alignment.center,
                child: child);
          },
        ));
    if (addedAward != null) {
      widget.collectionInfo.awards.add(addedAward);
      shouldLoad.value = true;
    }
  }

  Drawer buildDrawer() {
    return Drawer(
        child: widget.collectionInfo.owner == globals.firebaseUser.uid
            ? ownerDrawer()
            : followerDrawer());
  }

  Widget followerDrawer() {
    return Column(
      children: <Widget>[
        AppBar(
          actions: <Widget>[Container()],
          backgroundColor: Colors.green,
          title: Text('Options'),
        ),
        Container(
          child: Row(
            children: <Widget>[
              Text('Order: '),
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
        globals.loadedCollections[widget.collectionInfo.docRef.documentID] ==
                null
            ? RaisedButton(
                child: Text('Add to My Collections'),
                onPressed: () {
                  addCollectionReference(
                      globals.firebaseUser,
                      widget.collectionInfo.docRef,
                      widget.collectionInfo.title, () {
                    setState(() {});
                  });
                },
              )
            : RaisedButton(
                child: Text('Remove from My Collections'),
                onPressed: () {
                  setState(() {
                    removeCollectionReference(
                      globals.firebaseUser,
                      widget.collectionInfo.docRef,
                    );
                    awards = [];
                    Navigator.pop(context);
                  });
                },
              ),
        FlatButton(
            child: SizedBox(
              height: 20,
              width: double.infinity,
              child: Row(
                children: <Widget>[
                  Text(
                    'Filter NSFW',
                  ),
                  Checkbox(
                    value: filter.value,
                    onChanged: (newValue) {
                      filter.value = newValue;
                      setState(() {});
                    },
                  )
                ],
              ),
            ),
            onPressed: () {
              filter.value = !filter.value;
              setState(() {});
            }),
        Spacer(),
      ],
    );
  }

  Widget ownerDrawer() {
    return Column(
      children: <Widget>[
        AppBar(
          actions: <Widget>[Container()],
          backgroundColor: Colors.green,
          title: Text('Options'),
        ),
        Container(
          child: Row(
            children: <Widget>[
              Text('Order: '),
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
        FlatButton(
            child: SizedBox(
              height: 20,
              width: double.infinity,
              child: Row(
                children: <Widget>[
                  Text(
                    'Visible to the public',
                  ),
                  Checkbox(
                    value: visibleToPublic,
                    onChanged: (newValue) {
                      visibleToPublic = newValue;
                      visibleToFriends |= visibleToPublic;
                      setState(() {});
                    },
                  )
                ],
              ),
            ),
            onPressed: () {
              visibleToPublic = !visibleToPublic;
              visibleToFriends |= visibleToPublic;
              setState(() {});
            }),
        FlatButton(
            child: SizedBox(
              height: 20,
              width: double.infinity,
              child: Row(
                children: <Widget>[
                  Text(
                    'Visible to friends',
                  ),
                  Checkbox(
                    value: visibleToFriends,
                    onChanged: (newValue) {
                      visibleToFriends = newValue;
                      visibleToPublic &= visibleToFriends;
                      setState(() {});
                    },
                  )
                ],
              ),
            ),
            onPressed: () {
              visibleToFriends = !visibleToFriends;
              visibleToPublic &= visibleToFriends;
              setState(() {});
            }),
        RaisedButton(
          child: Text('New Document'),
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
                              controller: urlController,
                              decoration:
                                  InputDecoration(hintText: 'Google Docs url'),
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
        FlatButton(
            child: SizedBox(
              height: 20,
              width: double.infinity,
              child: Row(
                children: <Widget>[
                  Text(
                    'Filter NSFW',
                  ),
                  Checkbox(
                    value: filter.value,
                    onChanged: (newValue) {
                      filter.value = newValue;
                      setState(() {});
                    },
                  )
                ],
              ),
            ),
            onPressed: () {
              filter.value = !filter.value;
              setState(() {});
            }),
        Spacer(),
        FlatButton(
          child: SizedBox(
              height: 20,
              width: double.infinity,
              child: Text(
                'Delete Document',
                style: TextStyle(color: Colors.red),
              )),
          onPressed: () {
            deleteCollection(widget.collectionInfo.docRef);
            awards = [];
            Navigator.pop(context);
            Navigator.pop(context, true);
          },
          padding: EdgeInsets.only(bottom: 20.0, left: 15.0),
        ),
      ],
    );
  }
}

class CollectionActions extends StatelessWidget {
  TextEditingController searchController = TextEditingController();
  String getText() {
    return searchController.text;
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
      IconButton(
        icon: Icon(Icons.search),
        onPressed: () {
          showMenu(
            context: context,
            position: RelativeRect.fromLTRB(100, 100, 0, 0),
            items: <PopupMenuEntry>[
              PopupMenuItem(
                child: Container(
                  child: TextField(
                    autocorrect: false,
                    controller: searchController,
                  ),
                  width: 250,
                ),
              )
            ],
          );
        },
      ),
      IconButton(
        icon: Icon(Icons.menu),
        onPressed: () {
          Scaffold.of(context).openEndDrawer();
        },
      )
    ]);
  }
}
