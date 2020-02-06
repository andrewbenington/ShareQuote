import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Awards/Award.dart';
import 'package:pearawards/Awards/AwardsStream.dart';
import 'package:pearawards/Profile/AddFriend.dart';

import 'package:pearawards/Collections/Collection.dart';
import 'package:pearawards/Collections/CollectionPage.dart';
import 'package:pearawards/Utils/DisplayTools.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;
import 'package:pearawards/App/LoginPage.dart';
import 'package:pearawards/Utils/Utils.dart';

import 'User.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage(this.uid);
  final String uid;
  @override
  State<StatefulWidget> createState() {
    return ProfilePageState();
  }
}

class ProfilePageState extends State<ProfilePage> {
  List following = [];
  List followers = [];
  String imageURL = '';
  String displayName;
  bool loading = false;
  bool verified = false;

  Map<String, Collection> collections = Map();
  List<AwardLoader> awards = [];
  Key tabKey = Key('tabbar');
  int tabIndex = 0;
  PrimitiveWrapper loaded = PrimitiveWrapper(0);
  PrimitiveWrapper shouldLoad = PrimitiveWrapper(false);
  PrimitiveWrapper isLoading = PrimitiveWrapper(false);
  PrimitiveWrapper noAwards = PrimitiveWrapper(false);
  PrimitiveWrapper filter = PrimitiveWrapper(false);
  PrimitiveWrapper numAwards = PrimitiveWrapper(0);
  List<Widget> tabPages;
  bool notifications = false;

  void initState() {
    super.initState();
    loadCollections();
    loadData();
  }

  Future<void> loadCollections() async {
    var coll = Firestore.instance.collection('users/${widget.uid}/collections');

    coll.getDocuments().then((colls) {
      for (DocumentSnapshot document in colls.documents) {
        loadCollectionFromReference(
            document.data['reference'], document.reference);
      }
    });
    if (coll == null) {
      error = true;
    }

    if (mounted) {
      setState(() {});
    }
  }

  loadCollectionFromReference(
      DocumentReference collection, DocumentReference reference) async {
    DocumentSnapshot document = await collection.get();
    if (!document.exists) {
      reference.delete();
      globals.loadedCollections.remove(document.documentID);
      return;
    }
    collections[document.documentID] = Collection(
        docRef: document.reference,
        title: document.data['name'],
        owner: document.data['owner'],
        lastEdited: document.data['lastEdit']);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> loadData() async {
    DocumentSnapshot me =
        await Firestore.instance.document('users/${widget.uid}').get();
    verified = (await Firestore.instance
            .document('verified_users/${widget.uid}')
            .get())
        .exists;
    imageURL = me.data['image'];
    displayName = me.data["display"];
    if (me.data["followers"] != null) {
      followers = me.data["followers"].keys.toList();
    } else {
      followers = [];
    }
    if (me.data["following"] != null) {
      following = me.data["following"].keys.toList();
    } else {
      following = [];
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Collection> orderedCollections = collections.values.toList();
    orderedCollections.sort((col1, col2) {
      if (col1.lastEdited == null && col2.lastEdited != null) {
        return 1;
      } else if (col1.lastEdited != null && col2.lastEdited == null) {
        return -1;
      } else if (col1.lastEdited == null && col2.lastEdited == null) {
        return 0;
      }
      return col2.lastEdited - col1.lastEdited;
    });
    if (imageURL == null) {
      loadData();
    } 
    tabPages = [
      AwardsStream(
        docRef: Firestore.instance.document('users/${widget.uid}'),
        shouldLoad: shouldLoad,
        isLoading: isLoading,
        noAwards: noAwards,
        filter: filter,
        numAwards: numAwards,
        refreshParent: () {
          if (mounted) {
            setState(() {});
          }
          rebuildAllChildren(context);
        },
      ),
      AwardsStream(
        docRef: Firestore.instance.document('users/${widget.uid}'),
        shouldLoad: shouldLoad,
        isLoading: isLoading,
        noAwards: noAwards,
        filter: filter,
        directoryName: 'created_awards',
        directReferences: true,
        refreshParent: () {
          setState(() {});
          rebuildAllChildren(context);
        },
      ),
      orderedCollections.length != 0
          ? SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return GridTile(
                      child: CollectionTile(
                    c: orderedCollections[index],
                    onChanged: loadCollections,
                  ));
                },
                childCount: orderedCollections.length,
              ),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300.0,
              ),
            )
          : SliverFillRemaining(
              child: Column(
                children: <Widget>[
                  Spacer(),
                  Text(
                    'No Collections',
                    style: TextStyle(
                        color: globals.theme.darkPrimary,
                        fontSize: 40,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Create one on the Collections screen',
                    style: TextStyle(
                      color: globals.theme.darkPrimary,
                      fontSize: 20,
                    ),
                  ),
                  Spacer()
                ],
              ),
            ),
    ];
    if(widget.uid == globals.firebaseUser.uid) {
      globals.profileTabPages = tabPages;
      tabIndex = globals.profileIndex;
    }
    Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
        backgroundColor: globals.theme.backgroundColor,
        endDrawer: buildDrawer(),
        body: Stack(children: [
          RefreshIndicator(
            onRefresh: () {
              return refreshAll();
            },
            child: DefaultTabController(
              initialIndex: tabIndex,
              key: tabKey,
              length: tabPages.length,
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverList(
                    delegate: SliverChildListDelegate([
                      _buildProfileDisplay(screenSize),
                    ]),
                  ),
                  SliverPersistentHeader(
                    floating: true,
                    delegate: SliverTabBarDelegate(
                      TabBar(
                        labelColor: Colors.white,
                        indicatorColor: globals.theme.backgroundColor,
                        labelPadding: EdgeInsets.symmetric(vertical: 10.0),
                        onTap: (index) {
                          shouldLoad.value = true;
                          rebuildAllChildren(context);
                          setState(() {
                            tabIndex = index;
                            if(widget.uid == globals.firebaseUser.uid) {
                              globals.profileIndex = index;
                            }
                          });
                        },
                        tabs: [
                          Tab(
                              icon: Icon(Icons.bookmark),
                              text: 'Received Awards'),
                          Tab(
                              icon: Icon(Icons.loyalty),
                              child: Text('Given Awards')),
                          Tab(
                              icon: Icon(Icons.collections_bookmark),
                              text: 'Collections'),
                          //Tab(icon: Icon(Icons.people), text: 'Friends'),
                        ],
                      ),
                    ),
                  ),
                  tabPages[tabIndex]
                ],
              ),
            ),
          ),
          !loading
              ? Container()
              : Center(
                  child: CircularProgressIndicator(),
                )
        ]));
  }

  Widget _buildProfileDisplay(Size screenSize) {
    return Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                fit: BoxFit.cover,
                image: NetworkImage(
                    'https://cdn.vox-cdn.com/thumbor/Al48-pEnyIn2rlgKX7MIHNmlE68=/0x0:5563x3709/1200x800/filters:focal(2302x1311:3192x2201)/cdn.vox-cdn.com/uploads/chorus_image/image/65752607/1048232144.jpg.0.jpg'))),
        child: Column(
          children: <Widget>[
            Container(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  _buildProfilePhoto(screenSize),
                  Spacer(),
                  _buildFollowButton(),
                  widget.uid != globals.firebaseUser.uid
                      ? Spacer()
                      : _buildFindPeopleButton(),
                  _buildNotificationButton(),
                  Spacer()
                ],
              ),
              margin: EdgeInsets.only(top: 30, bottom: 10, left: 22.0),
            ),
            _buildDisplayName(),
            Padding(
              padding: EdgeInsets.only(left: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  ButtonTheme(
                    padding: EdgeInsets.all(0),
                    child: FlatButton(
                      onPressed: () {
                        toUserList(followers, "Followers");
                      },
                      splashColor: Colors.transparent,
                      child: ShadowText(
                        text:
                            "${followers.length} Follower${followers.length == 1 ? "" : "s"}",
                        offset: 4.0,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0),
                      ),
                    ),
                  ),
                  ShadowText(
                    text: " • ",
                    offset: 4.0,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0),
                  ),
                  ButtonTheme(
                    padding: EdgeInsets.all(0),
                    child: FlatButton(
                      splashColor: Colors.transparent,
                      onPressed: () {
                        toUserList(following, "Following");
                      },
                      child: ShadowText(
                        text: "${following.length} Following",
                        offset: 4.0,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0),
                      ),
                    ),
                  ),
                  ShadowText(
                    text: " • ",
                    offset: 4.0,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0),
                  ),
                  ShadowText(
                    text:
                        "${numAwards.value} Award${numAwards.value == 1 ? "" : "s"}",
                    offset: 4.0,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0),
                  )
                ],
              ),
            )
          ],
        ),
        padding: EdgeInsets.only(bottom: 10.0));
  }

  Widget _buildFindPeopleButton() {
    return globals.firebaseUser.uid != widget.uid
        ? Container()
        : Stack(children: [
            RaisedButton(
                elevation: 8,
                color: globals.theme.primaryColor,
                child: Text(
                  "Discover People",
                  style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                onPressed: addPeople,
                shape: StadiumBorder()),
          ]);
  }

  Widget _buildNotificationButton() {
    return globals.firebaseUser.uid == widget.uid
        ? Container()
        : Stack(children: [
            RaisedButton(
                elevation: 8,
                color: globals.theme.primaryColor,
                child: Icon(
                  notifications
                      ? Icons.notifications_active
                      : Icons.notifications,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (!loading) {
                    notifications = !notifications;
                    setState(() {});
                  }
                },
                shape: StadiumBorder()),
          ]);
  }

  Widget _buildFollowButton() {
    return globals.firebaseUser.uid == widget.uid
        ? Container()
        : Stack(children: [
            RaisedButton(
                elevation: 8,
                color: globals.theme.primaryColor,
                child: Text(
                  followers.indexOf(globals.firebaseUser.uid) >= 0
                      ? "Following"
                      : "Follow",
                  style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                onPressed: () {
                  if (!loading) {
                    sendFollowRequest();
                  }
                },
                shape: StadiumBorder()),
          ]);
  }

  Future<void> sendFollowRequest() async {
    loading = true;
    setState(() {});
    HttpsCallable post = CloudFunctions.instance
        .getHttpsCallable(functionName: "sendFollowRequest");
    var result = await post.call({
      "remove":
          followers.indexOf(globals.firebaseUser.uid) >= 0 ? "true" : "false",
      "from": globals.firebaseUser.uid,
      "name": globals.firebaseUser.displayName,
      "to": widget.uid
    }).catchError((error) {
      print(error);
      loading = false;
      return;
    });
    if (followers.indexOf(globals.firebaseUser.uid) >= 0) {
      followers.remove(globals.firebaseUser.uid);
    } else {
      followers.add(globals.firebaseUser.uid);
    }
    loading = false;
    setState(() {});
    print(result.data);
  }

  Widget _buildDisplayName() {
    return Container(
        alignment: Alignment.centerLeft,
        margin: EdgeInsets.only(left: 25.0),
        child: ShadowText(
          text: displayName == null ? "" : displayName + (verified ? " ✓" : ""),
          offset: 4.0,
          style: TextStyle(
              fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ));
  }

  Widget _buildProfilePhoto(Size screenSize) {
    return Align(
      child: Container(
        height: screenSize.width * 0.25,
        width: screenSize.width * 0.25,
        decoration: imageURL == null || imageURL == ""
            ? BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
                border: Border.all(width: 3.0, color: Colors.white),
                boxShadow: [BoxShadow()])
            : BoxDecoration(
                boxShadow: [
                  BoxShadow(
                      offset: Offset(4.0, 4.0),
                      color: Colors.black.withOpacity(0.5))
                ],
                shape: BoxShape.circle,
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: NetworkImage(imageURL),
                ),
                color: Colors.white,
                border: Border.all(width: 4.0, color: Colors.white),
              ),
      ),
      alignment: Alignment(-0.8, 0),
    );
  }

  addPeople() async {
    await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              AddFriend(title: 'People you may like', following: following),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
                scale: animation.drive(CurveTween(curve: Curves.ease)),
                alignment: Alignment.center,
                child: child);
          },
        ));
  }

  refreshAll() async {
    await Future.wait([loadCollections(), loadData()]);
    isLoading.value = false;
    shouldLoad.value = true;
    //rebuildAllChildren(context);
    setState(() {});
  }

  Future<void> dontAddFollower() async {
    return;
  }

  Future<void> addFollowing(String uid, bool remove) async {
    HttpsCallable post = CloudFunctions.instance
        .getHttpsCallable(functionName: "sendFollowRequest");
    await post.call({
      "remove": remove ? "true" : "false",
      "from": globals.firebaseUser.uid,
      "name": globals.firebaseUser.displayName,
      "to": uid
    }).catchError((error) {
      print(error);
      return;
    });
    if (remove) {
      following.remove(uid);
    } else {
      following.add(uid);
    }
  }

  Drawer buildDrawer() {
    return Drawer(
      child: Column(
        children: <Widget>[
          AppBar(
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
                        color: mostRecent ? globals.theme.primaryColor : Colors.black87),
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
          RaisedButton(
            child: Text('Log Out'),
            onPressed: () {
              globals.firebaseAuth.signOut();
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) => LoginPage(),
              ));
            },
          ),
        ],
      ),
    );
  }

  toUserPage(String uid) async {
    await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
            appBar: AppBar(
              title: Text("User"),
            ),
            body: ProfilePage(uid),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
                scale: animation.drive(CurveTween(curve: Curves.ease)),
                alignment: Alignment.center,
                child: child);
          },
        ));
    refreshAll();
  }

  toUserList(List users, String title) async {
    await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
            backgroundColor: globals.theme.backgroundColor,
            appBar: AppBar(
              title: Text(title),
            ),
            body: users.length != 0
                ? GridView(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 500.0, childAspectRatio: 6.0),
                    children: List.generate(users.length, (index) {
                    
                      return users[index] != null ? UserTab(
                        onPressed: () {
                          toUserPage(users[index]);
                        },
                        uid: users[index],
                      ) : Container();
                    }))
                : Center(
                    child: Column(
                      children: <Widget>[
                        Spacer(),
                        Text(
                          'There\'s no one here :(',
                          style: TextStyle(
                              color: globals.theme.darkPrimary,
                              fontSize: 40,
                              fontWeight: FontWeight.bold),
                        ),
                        Spacer()
                      ],
                    ),
                  ),
            /*floatingActionButton: FloatingActionButton(
              child: Icon(Icons.person_add),
              onPressed: newFriend,
            ),*/
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
                scale: animation.drive(CurveTween(curve: Curves.ease)),
                alignment: Alignment.center,
                child: child);
          },
        ));
    refreshAll();
  }
}
