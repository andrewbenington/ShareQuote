import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/AddFriend.dart';
import 'package:pearawards/HomePage.dart';

import 'Collection.dart';
import 'CollectionPage.dart';
import 'Globals.dart' as globals;
import 'LoginPage.dart';

List<User> friends = [];

class User {
  User({this.displayName, this.imageUrl, this.uid});
  String imageUrl;
  String displayName;
  String uid;
}

class ProfilePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ProfilePageState();
  }
}

class ProfilePageState extends State<ProfilePage> {
  List<Collection> collections = [];
  Key tabKey = Key("tabbar");
  int tabIndex = 0;
  String imageURL = "";

  loadCollections() async {
    var coll = Firestore.instance
        .collection('users')
        .document(globals.firebaseUser.uid)
        .collection('collections');
    collections = await coll.getDocuments().then((colls) {
      return colls.documents.map((document) {
        if (globals.loadedCollections[document.documentID] == null) {
          globals.loadedCollections[document.documentID] =
              Collection(docRef: document.reference);
        }
        return globals.loadedCollections[document.documentID];
      }).toList();
    });
    if (coll == null) {
      error = true;
    }
    if (mounted) {
      setState(() {});
    }
  }

  loadData() async {
    DocumentSnapshot me = await Firestore.instance
        .document('users/' + globals.firebaseUser.uid)
        .get();
    imageURL = me.data["image"];
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> tabPages = [
      SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            return GridTile(child: CollectionTile(c: collections[index]));
          },
          childCount: collections.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
      ),
      StreamBuilder(
          stream: Firestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            var data = snapshot.data;
            List<dynamic> users = [];
            if (data != null) {
              users = snapshot.data.documents;
            }
            return SliverList(
              delegate:
                  SliverChildBuilderDelegate((BuildContext context, int index) {
                return Text(users[index].data["display"] == null
                    ? "???"
                    : users[index].data[
                        "display"]); // This will build a list of Text widgets with the values from the List<String> that is stored in the streambuilder snapshot
              }, childCount: users.length),
            );
          }),
      SliverList(
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          return Text(friends[index]
              .displayName); // This will build a list of Text widgets with the values from the List<String> that is stored in the streambuilder snapshot
        }, childCount: friends.length),
      )
    ];
    Size screenSize = MediaQuery.of(context).size;
    loadCollections();
    loadFriends();
    loadData();
    return Scaffold(
        backgroundColor: Colors.green[200],
        endDrawer: buildDrawer(),
        floatingActionButton: tabIndex == 2
            ? FloatingActionButton(
                child: Icon(Icons.person_add),
                onPressed: () {
                  newFriend();
                },
              )
            : Container(),
        body: DefaultTabController(
          key: tabKey,
          length: 3,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverList(
                delegate: SliverChildListDelegate([
                  _buildProfileDisplay(screenSize),
                ]),
              ),
              SliverAppBar(
                floating: true,
                snap: true,
                title: TabBar(
                  onTap: (index) {
                    setState(() {
                      tabIndex = index;
                    });
                  },
                  tabs: [
                    Tab(
                        icon: Icon(Icons.collections_bookmark),
                        text: "Collections"),
                    Tab(icon: Icon(Icons.view_agenda), text: "Awards"),
                    Tab(icon: Icon(Icons.people), text: "Friends"),
                  ],
                ),
              ),
              tabPages[tabIndex]
            ],
          ),
        ));
  }

  Widget _buildProfileDisplay(Size screenSize) {
    return Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                fit: BoxFit.fitHeight,
                image: NetworkImage(
                    "https://cdn.vox-cdn.com/thumbor/Al48-pEnyIn2rlgKX7MIHNmlE68=/0x0:5563x3709/1200x800/filters:focal(2302x1311:3192x2201)/cdn.vox-cdn.com/uploads/chorus_image/image/65752607/1048232144.jpg.0.jpg"))),
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                _buildProfilePhoto(screenSize),
                _buildDisplayName()
              ],
            ),
            Container(
              height: MediaQuery.of(context).size.width * 0.4,
              child: SettingsButton(),
            )
          ],
        ));
  }

  Widget _buildDisplayName() {
    return Container(
        alignment: Alignment.center,
        margin: EdgeInsets.symmetric(vertical: 20.0),
        child: Text(globals.firebaseUser.displayName,
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white)));
  }

  Widget _buildProfilePhoto(Size screenSize) {
    return Align(
      child: Container(
        height: screenSize.width * 0.4,
        width: screenSize.width * 0.4,
        margin: EdgeInsets.only(top: 50, bottom: 10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            fit: BoxFit.fill,
            image: NetworkImage(imageURL),
          ),
          border: Border.all(width: 5.0, color: Colors.white),
        ),
      ),
      alignment: Alignment.center,
    );
  }

  newFriend() async {
    await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => AddFriend(
            title: "Add Friends",
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
                scale: animation.drive(CurveTween(curve: Curves.ease)),
                alignment: Alignment.center,
                child: child);
          },
        ));
  }

  loadFriends() async {
    List<DocumentSnapshot> friends = (await Firestore.instance
            .document('users/' + globals.firebaseUser.uid)
            .collection("friends")
            .getDocuments())
        .documents;
    for (DocumentSnapshot doc in friends) {
      addFriend(doc.documentID);
    }
  }

  addFriend(String uid) async {
    DocumentSnapshot user =
        await Firestore.instance.document('users/' + uid).get();
    if (user.exists) {
      friends.add(User(
          displayName: user.data["display"],
          imageUrl: user.data["image"],
          uid: user.documentID));
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
          RaisedButton(
            child: Text("Log Out"),
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
}

class SettingsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      child: IconButton(
        icon: Icon(
          Icons.settings,
          color: Colors.white,
          size: 35,
        ),
        onPressed: () {
          Scaffold.of(context).openEndDrawer();
        },
      ),
      alignment: Alignment(0.9, 0.0),
    );
  }
}
