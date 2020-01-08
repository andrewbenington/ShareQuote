import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Profile/User.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;

Map friends;
Map sentRequests;

class TagUser extends StatefulWidget {
  @override
  _TagUserState createState() => _TagUserState();
}

class _TagUserState extends State<TagUser> {
  List<DocumentSnapshot> users = [];
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
      backgroundColor: Colors.green[200],
      body: StreamBuilder(
          stream: Firestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            var data = snapshot.data;
            
            if (data != null) {
              users = snapshot.data.documents;
            }
            return users.length == null
                ? Container()
                : ListView.builder(
                    itemBuilder: (BuildContext context, int index) {
                      return userTab(
                          User(
                              displayName: users[index].data['display'],
                              imageUrl: users[index].data['image'],
                              uid: users[index].documentID),
                          index == selectedIndex,
                          index); // This will build a list of Text widgets with the values from the List<String> that is stored in the streambuilder snapshot
                    },
                    itemCount: users.length);
          }),
    );
  }

  Widget userTab(User user, bool selected, int index) {
    return Padding(
      child: RaisedButton(
        color: Colors.white,
        disabledColor: Colors.green[100],
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
                      style: TextStyle(fontSize: 20.0, color: Colors.black),
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
