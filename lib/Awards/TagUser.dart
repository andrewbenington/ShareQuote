import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Profile/User.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;
import 'package:pearawards/Utils/Utils.dart';

import 'AwardsStream.dart';

Map friends;
Map sentRequests;

class TagUser extends StatefulWidget {
  @override
  _TagUserState createState() => _TagUserState();
}

class _TagUserState extends State<TagUser> {
  List<DocumentSnapshot> users = [];
  PrimitiveWrapper searchText = PrimitiveWrapper("");
  int selectedIndex;
  @override
  void initState() {
    super.initState();
    loadFriends();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: globals.theme.primaryColor,
          leading: IconButton(
            icon: Icon(Icons.close, size: 30),
            onPressed: () {
              Navigator.pop(context, null);
            },
          ),
          title: Text('Tag Someone'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.check, size: 30),
              onPressed: () {
                Navigator.pop(context, users[selectedIndex].documentID);
              },
            ),
          ],
        ),
        backgroundColor: globals.theme.backgroundColor,
        body: CustomScrollView(slivers: [
          SliverList(
              delegate: SliverChildListDelegate([
            Container(
              padding: EdgeInsets.all(5),
              color: globals.theme.primaryColor,
              height: 48.0,
              child: TextField(
                onChanged: (content) {
                  searchText.value = content;
                  setState(() {});
                },
                style: TextStyle(color: globals.theme.textColor, fontSize: 20),
                scrollPadding: EdgeInsets.symmetric(vertical: 0.0),
                cursorColor: globals.theme.backgroundColor,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: new BorderRadius.circular(25.0),
                      borderSide: BorderSide(
                          color: globals.theme.primaryColor, width: 2)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: new BorderRadius.circular(25.0),
                      borderSide: BorderSide(
                          color: globals.theme.primaryColor, width: 2)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: new BorderRadius.circular(25.0),
                      borderSide: BorderSide(
                          color: globals.theme.darkPrimary, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 0.0, horizontal: 15.0),
                  fillColor: globals.theme.lightPrimary,
                  filled: true,
                  hintStyle: TextStyle(color: Colors.white, fontSize: 20),
                  hintText: "Search",
                ),
              ),
            )
          ])),
          searchText.value == "" || searchText.value == null
              ? SliverList(
                  delegate: SliverChildListDelegate([Container()]),
                )
              : StreamBuilder(
                  stream: Firestore.instance
                      .collection('users')
                      .where('display_insensitive',
                          isGreaterThanOrEqualTo:
                              searchText.value.toUpperCase())
                      .where('display_insensitive',
                          isLessThan:
                              incrementString(searchText.value.toUpperCase()))
                      .limit(50)
                      .snapshots(),
                  builder: (context, snapshot) {
                    var data = snapshot.data;

                    if (data != null) {
                      users = snapshot.data.documents;
                    }
                    return users.length == null
                        ? Container()
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return userTab(
                                    User(
                                        displayName:
                                            users[index].data['display'],
                                        imageUrl: users[index].data['image'],
                                        uid: users[index].documentID),
                                    index == selectedIndex,
                                    index);
                              },
                              childCount: snapshot.hasData ? users.length : 0,
                            ),
                          );
                  }),
        ]));
  }

  Widget userTab(User user, bool selected, int index) {
    return Padding(
      child: Container(
        height: 60,
        child: RaisedButton(
          color: globals.theme.cardColor,
          disabledColor: globals.theme.lightPrimary,
          disabledTextColor: globals.theme.backTextColor,
          child: Row(children: <Widget>[
            Container(
              width: 50.0,
              height: 50.0,
              margin: EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: NetworkImage(user.imageUrl),
                ),
              ),
            ),
            Expanded(
              child: FractionallySizedBox(
                widthFactor: 1,
                child: Container(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: RichText(
                      text: TextSpan(
                        text: user.displayName,
                        style: TextStyle(
                            fontSize: 20.0, color: globals.theme.textColor),
                      ),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                ),
              ),
            ),
          ]),
          shape: StadiumBorder(),
          onPressed: selectedIndex == index
              ? null
              : () {
                  setState(() {
                    selectedIndex = index;
                  });
                },
        ),
      ),
      padding: EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
    );
  }

  loadFriends() async {
    var me = await Firestore.instance
        .document('users/${globals.firebaseUser.uid}')
        .get();
    friends = me.data['friends'];
    sentRequests = me.data['sentRequests'];
    if (friends == null) {
      friends = Map();
    }
    if (sentRequests == null) {
      sentRequests = Map();
    }
    setState(() {});
  }
}
