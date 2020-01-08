import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Awards/Award.dart';
import 'package:pearawards/Awards/AwardsStream.dart';
import 'package:pearawards/Profile/AddFriend.dart';

import 'package:pearawards/Collections/Collection.dart';
import 'package:pearawards/Collections/CollectionPage.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;
import 'package:pearawards/App/LoginPage.dart';
import 'package:pearawards/Utils/Utils.dart';

import 'User.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage(this.user);
  final User user;
  @override
  State<StatefulWidget> createState() {
    return ProfilePageState();
  }
}

class ProfilePageState extends State<ProfilePage> {
  Map<String, User> friends = Map();
  Map<String, Collection> collections = Map();
  List<AwardLoader> awards = [];
  Key tabKey = Key('tabbar');
  int tabIndex = 0;
  String imageURL = '';
  PrimitiveWrapper loaded = PrimitiveWrapper(0);
  PrimitiveWrapper shouldLoad = PrimitiveWrapper(false);
  PrimitiveWrapper isLoading = PrimitiveWrapper(false);
  PrimitiveWrapper noAwards = PrimitiveWrapper(false);

  initState() {
    super.initState();
    loadCollections();
    loadFriends();
    loadData();
    loadAwards();
  }

  Future<void> loadCollections() async {
    var coll =
        Firestore.instance.collection('users/${widget.user.uid}/collections');

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
        await Firestore.instance.document('users/${widget.user.uid}').get();
    widget.user.imageUrl = me.data['image'];
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> loadAwards() async {
    DocumentSnapshot dSnapshot =
        await Firestore.instance.document('users/${widget.user.uid}').get();
    if (!dSnapshot.exists) {
      Navigator.pop(context, true);
      return;
    }
    loaded.value = 0;
    awards = [];
    QuerySnapshot snapshot = await Firestore.instance
        .collection('users/${widget.user.uid}/awards')
        .getDocuments();
    awards = snapshot.documents.map((doc) {
      return AwardLoader(doc.reference, doc.data['reference'], null, loaded);
    }).toList();
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
    if (widget.user.imageUrl == null) {
      loadData();
    }
    List<Widget> tabPages = [
      AwardsStream(
        docRef: Firestore.instance.document('users/${widget.user.uid}'),
        title: widget.user.displayName,
        shouldLoad: shouldLoad,
        isLoading: isLoading,
        noAwards: noAwards,
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
                        color: Colors.green[800],
                        fontSize: 40,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Create one on the Collections screen',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontSize: 20,
                    ),
                  ),
                  Spacer()
                ],
              ),
            ),
      friends.length != 0
          ? SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 500.0, childAspectRatio: 6.0),
              delegate:
                  SliverChildBuilderDelegate((BuildContext context, int index) {
                return friendTab(friends.values.toList()[
                    index]); // This will build a list of Text widgets with the values from the List<String> that is stored in the streambuilder snapshot
              }, childCount: friends.length == 0 ? 1 : friends.length),
            )
          : SliverFillRemaining(
              child: Column(
                children: <Widget>[
                  Spacer(),
                  Text(
                    'No Friends',
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
                  Spacer()
                ],
              ),
            )
    ];
    Size screenSize = MediaQuery.of(context).size;

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
        body: RefreshIndicator(
          onRefresh: () {
            return refreshAll();
          },
          child: DefaultTabController(
            key: tabKey,
            length: 3,
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
                      onTap: (index) {
                        setState(() {
                          tabIndex = index;
                        });
                      },
                      tabs: [
                        Tab(icon: Icon(Icons.view_agenda), text: 'Awards'),
                        Tab(
                            icon: Icon(Icons.collections_bookmark),
                            text: 'Collections'),
                        Tab(icon: Icon(Icons.people), text: 'Friends'),
                      ],
                    ),
                  ),
                ),
                tabPages[tabIndex]
              ],
            ),
          ),
        ));
  }

  Widget _buildProfileDisplay(Size screenSize) {
    return Container(
      decoration: BoxDecoration(
          image: DecorationImage(
              fit: BoxFit.fitHeight,
              image: NetworkImage(
                  'https://cdn.vox-cdn.com/thumbor/Al48-pEnyIn2rlgKX7MIHNmlE68=/0x0:5563x3709/1200x800/filters:focal(2302x1311:3192x2201)/cdn.vox-cdn.com/uploads/chorus_image/image/65752607/1048232144.jpg.0.jpg'))),
      child: Column(
        children: <Widget>[_buildProfilePhoto(screenSize), _buildDisplayName()],
      ),
    );
  }

  Widget _buildDisplayName() {
    return Container(
        alignment: Alignment.center,
        margin: EdgeInsets.symmetric(vertical: 20.0),
        child: Text(widget.user.displayName,
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
        decoration: widget.user.imageUrl == null
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(width: 5.0, color: Colors.white),
              )
            : BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: NetworkImage(widget.user.imageUrl),
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
            title: 'Add Friends',
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
                scale: animation.drive(CurveTween(curve: Curves.ease)),
                alignment: Alignment.center,
                child: child);
          },
        ));
  }

  refreshAll() async {
    await Future.wait([loadFriends(), loadCollections(), loadData()]);
    setState(() {});
  }

  Future<void> loadFriends() async {
    DocumentSnapshot me =
        (await Firestore.instance.document('users/${widget.user.uid}').get());
    var tempFriends = me.data['friends'];
    await Future.wait(List.generate(tempFriends.length, (index) {
      if (friends[tempFriends.keys.elementAt(index)] == null) {
        return addFriend(tempFriends.keys.elementAt(index));
      } else {
        return dontAddFriend();
      }
    }));
  }

  Future<void> dontAddFriend() async {
    return;
  }

  Future<void> addFriend(String uid) async {
    DocumentSnapshot user =
        await Firestore.instance.document('users/$uid').get();
    if (user.exists) {
      friends[uid] = (User(
          displayName: user.data['display'],
          imageUrl: user.data['image'],
          uid: user.documentID));
    }
  }

  Drawer buildDrawer() {
    return Drawer(
      child: Column(
        children: <Widget>[
          AppBar(
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

  Widget friendTab(User friend) {
    return Padding(
      child: RaisedButton(
          onPressed: () {
            toFriendPage(friend);
          },
          child: Row(children: <Widget>[
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                height: MediaQuery.of(context).size.height / 15,
                width: MediaQuery.of(context).size.height / 15,
                margin: EdgeInsets.symmetric(vertical: 5.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage(friend.imageUrl),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RichText(
                    text: TextSpan(
                      text: friend.displayName,
                      style: TextStyle(fontSize: 20, color: Colors.black),
                    ),
                  ),
                ),
                //padding: EdgeInsets.symmetric(horizontal: 5.0),
              ),
            ),
          ]),
          shape: StadiumBorder(),
          color: Colors.white),
      padding: EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
    );
  }

  toFriendPage(User friend) async {
    await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
              appBar: AppBar(
                title: Text('Friend'),
              ),
              body: ProfilePage(friend)),
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

class SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  SliverTabBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  bool shouldRebuild(SliverTabBarDelegate oldDelegate) {
    return false;
  }

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.green,
      child: _tabBar,
    );
  }
}
