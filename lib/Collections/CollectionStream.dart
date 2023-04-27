import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Awards/AddQuote.dart';
import 'package:pearawards/Awards/Award.dart';
import 'package:pearawards/Awards/AwardsStream.dart';
import 'package:pearawards/Awards/TagUser.dart';
import 'package:pearawards/Collections/CollectionFunctions.dart';
import 'package:pearawards/Utils/Converter.dart';
import 'package:pearawards/Utils/Upload.dart';
import 'package:pearawards/Utils/Utils.dart';
import 'package:share/share.dart';
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
  PrimitiveWrapper mostRecent = PrimitiveWrapper(true);
  PrimitiveWrapper searchText = PrimitiveWrapper("");
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
        backgroundColor: globals.theme.primaryColor,
        actions: [
          CollectionActions(searchText, () {
            setState(() {});
          })
        ],
        leading: IconButton(
          icon: Icon(Icons.close, size: 30),
          onPressed: () {
            searchText.value = "";
            Navigator.of(context).pop(updated);
          },
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
      backgroundColor: globals.theme.backgroundColor,
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
                              color: globals.theme.backTextColor,
                              fontSize: 40,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Tap the \'+\' button to add one!',
                          style: TextStyle(
                            color: globals.theme.textColor,
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
                  SliverList(
                    delegate: SliverChildListDelegate([Container()]),
                  ),
                  AwardsStream(
                    collectionInfo: widget.collectionInfo,
                    docRef: widget.collectionInfo.docRef,
                    shouldLoad: shouldLoad,
                    mostRecent: mostRecent,
                    isLoading: isLoading,
                    noAwards: noAwards,
                    filter: filter,
                    refreshParent: () {
                      if (mounted) {
                        setState(() {});
                        rebuildAllChildren(context);
                      }
                    },
                    searchText: searchText,
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
        backgroundColor: globals.theme.primaryColor,
        onPressed: () {
          newAward();
        },
        tooltip: 'Increment',
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
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
        child: widget.collectionInfo.owner == globals.me.uid
            ? ownerDrawer(() {
                setState(() {});
              })
            : followerDrawer());
  }

  Widget followerDrawer() {
    return Column(
      children: <Widget>[
        AppBar(
          actions: <Widget>[Container()],
          backgroundColor: globals.theme.primaryColor,
          title: Text('Options'),
        ),
        Container(
          child: Row(
            children: <Widget>[
              Text('Order: '),
              Expanded(
                child: ChoiceChip(
                  labelStyle: TextStyle(
                      color: mostRecent.value ? Colors.green : Colors.black87),
                  label: Text('Latest'),
                  onSelected: (bool selected) {
                    setState(() {
                      mostRecent.value = selected;
                    });
                  },
                  selected: mostRecent.value,
                ),
              ),
              Expanded(
                child: ChoiceChip(
                  label: Text('First'),
                  onSelected: (bool selected) {
                    setState(() {
                      mostRecent.value = !selected;
                    });
                  },
                  selected: !mostRecent.value,
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
                      widget.collectionInfo.docRef, widget.collectionInfo.title,
                      () {
                    setState(() {});
                  });
                },
              )
            : RaisedButton(
                child: Text('Remove from My Collections'),
                onPressed: () {
                  setState(() {
                    removeCollectionReference(
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
        RaisedButton(
          child: Text('Invite a friend'),
          onPressed: inviteFriend,
        ),
        RaisedButton(
          child: Text('Share collection'),
          onPressed: () {
            Share.share(
                'https://sharequote.app/collection?path=${widget.collectionInfo.docRef.path}');
          },
        ),
        Spacer(),
      ],
    );
  }

  Widget ownerDrawer(Function refresh) {
    return Column(
      children: <Widget>[
        AppBar(
          actions: <Widget>[Container()],
          backgroundColor: globals.theme.primaryColor,
          title: Text('Options'),
        ),
        Container(
          child: Row(
            children: <Widget>[
              Text('Order: '),
              Expanded(
                child: ChoiceChip(
                  labelStyle: TextStyle(
                      color: mostRecent.value ? Colors.green : Colors.black87),
                  label: Text('Latest'),
                  onSelected: (bool selected) {
                    setState(() {
                      mostRecent.value = selected;
                      refresh();
                    });
                  },
                  selected: mostRecent.value,
                ),
              ),
              Expanded(
                child: ChoiceChip(
                  label: Text('First'),
                  onSelected: (bool selected) {
                    setState(() {
                      mostRecent.value = !selected;
                    });
                  },
                  selected: !mostRecent.value,
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
        /*FlatButton(
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
            }),*/
        RaisedButton(
          child: Text('Sync With Google Doc'),
          onPressed: () {
            setState(() {
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(
                          'First, make sure to publish your Google Doc (File->Publish). Paste the URL here. Make sure it ends with \n\'\/pub\' instead of \'\/edit\'.'),
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
                          child: new Text(
                            'CANCEL',
                            style: TextStyle(color: globals.theme.primaryColor),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        new FlatButton(
                          child: new Text(
                            'ADD',
                            style: TextStyle(color: globals.theme.primaryColor),
                          ),
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
          child: Text('Invite a friend'),
          onPressed: inviteFriend,
        ),
        RaisedButton(
          child: Text('Share collection'),
          onPressed: () {
            Share.share(
                'https://sharequote.app/collection?path=${widget.collectionInfo.docRef.path}');
          },
        ),
        Spacer(),
        FlatButton(
          child: SizedBox(
              height: 20,
              width: double.infinity,
              child: Text(
                'Delete Collection',
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

  /* 
  invite notification
{
    "name": name of inviter
    "title" : name of collection
    "path" : doc path of collection
} */

  inviteFriend() async {
    String uid = await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => TagUser(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
                scale: animation.drive(CurveTween(curve: Curves.ease)),
                alignment: Alignment.center,
                child: child);
          },
        ));
    if (uid != null) {
      sendNotification(uid, {
        "notification": "4",
        "name": globals.me.displayName,
        "title": widget.collectionInfo.title,
        "path": widget.collectionInfo.docRef.path
      });
    }
  }
}

class CollectionActions extends StatefulWidget {
  CollectionActions(this.searchText, this.refresh);
  final PrimitiveWrapper searchText;
  final Function refresh;

  @override
  State<StatefulWidget> createState() {
    return CollectionActionsState();
  }
}

class CollectionActionsState extends State<CollectionActions> {
  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    //searchController.text = widget.searchText.value;
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
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onTap: () {
                          int i = 0;
                        },
                        onChanged: (text) {
                          widget.searchText.value = text;
                          widget.refresh();
                          setState(() {});
                          rebuildAllChildren(context);
                        },
                        autocorrect: false,
                      ),
                    ),
                    IconButton(
                      icon:
                          Icon(Icons.close, color: globals.theme.primaryColor),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    )
                  ]),
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
