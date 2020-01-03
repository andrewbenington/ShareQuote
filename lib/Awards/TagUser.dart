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
            Navigator.pop(context, false);
          },
        ),
        title: Text("Tag Someone"),
      ),
      backgroundColor: Colors.green[200],
      body: StreamBuilder(
          stream: Firestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            var data = snapshot.data;
            List<DocumentSnapshot> users = [];
            if (data != null) {
              users = snapshot.data.documents;
            }
            return users.length == null
                ? Container()
                : ListView.builder(
                    itemBuilder: (BuildContext context, int index) {
                      return userTab(
                          User(
                              displayName: users[index].data["display"],
                              imageUrl: users[index].data["image"],
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

  confirmFriendRequest(String uid) async {
    DocumentReference me = Firestore.instance
        .collection("users")
        .document(globals.firebaseUser.uid);
    DocumentReference them =
        Firestore.instance.collection("users").document(uid);
    if ((await them.get()).data["friends"] == null) {
      them.setData({
        "friends": {globals.firebaseUser.uid: true}
      }, merge: true);
      them.updateData({
        "sentRequests." + globals.firebaseUser.uid: null,
        "lastNotification": DateTime.now().microsecondsSinceEpoch
      });
    } else {
      them.updateData({
        "friends." + globals.firebaseUser.uid: true,
        "sentRequests." + globals.firebaseUser.uid: null,
        "lastNotification": DateTime.now().microsecondsSinceEpoch
      });
    }

    me.updateData({
      "friends." + uid: true,
      "sentRequests." + uid: null,
      "lastNotification": DateTime.now().microsecondsSinceEpoch
    });
    loadFriends();
  }

  sendFriendRequest(String uid) async {
    DocumentReference me = Firestore.instance
        .collection("users")
        .document(globals.firebaseUser.uid);
    DocumentReference them =
        Firestore.instance.collection("users").document(uid);
    Map data = (await them.get()).data;
    Map theirFriends = data["friends"];
    sentRequests = (await me.get()).data["sentRequests"];
    if (theirFriends == null) {
      them.updateData({
        "friends": {globals.firebaseUser.uid: false},
        "lastNotification": DateTime.now().microsecondsSinceEpoch
      });
    } else {
      if (theirFriends[globals.firebaseUser.uid] == null) {
        theirFriends[globals.firebaseUser.uid] = false;
      } else {
        theirFriends[globals.firebaseUser.uid] = true;
        sentRequests.remove(uid);
        me.updateData({"friends." + uid: true, "sentRequests": sentRequests});
      }
      them.updateData({
        "friends": theirFriends,
        "lastNotification": DateTime.now().microsecondsSinceEpoch
      });
    }
    them.collection("notifications").document().setData({
      "notification": 3,
      "uid": globals.firebaseUser.uid,
      "time": DateTime.now().microsecondsSinceEpoch,
      "name": globals.firebaseUser.displayName,
    });

    Firestore.instance
        .document("users/" + globals.firebaseUser.uid)
        .updateData({"sentRequests." + uid: true});
    loadFriends();
  }

  cancelFriendRequest(String uid) async {}

  loadFriends() async {
    var me = await Firestore.instance
        .document("users/" + globals.firebaseUser.uid)
        .get();
    friends = me.data["friends"];
    sentRequests = me.data["sentRequests"];
    if (friends == null) {
      friends = Map();
    }
    if (sentRequests == null) {
      sentRequests = Map();
    }
    setState(() {});
  }
}
