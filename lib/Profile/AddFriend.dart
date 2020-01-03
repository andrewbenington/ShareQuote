import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;
import 'User.dart';

Map friends;
Map sentRequests;

class AddFriend extends StatefulWidget {
  AddFriend({Key key, this.document, this.title}) : super(key: key);

  final DocumentReference document;
  final String title;

  @override
  _AddFriendState createState() => _AddFriendState();
}

class _AddFriendState extends State<AddFriend> {
  List<User> users = [];
  bool mostRecent = true;
  String errorMessage = "";

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
        title: Text("Add Friends"),
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
            return friends == null
                ? Container()
                : ListView.builder(
                    itemBuilder: (BuildContext context, int index) {
                      if (sentRequests != null &&
                          friends[users[index].documentID] != true &&
                          users[index].documentID != globals.firebaseUser.uid) {
                        return userTab(
                            users[index].documentID,
                            users[index].data["display"],
                            users[index].data["image"],
                            friends[users[index].documentID] == false,
                            sentRequests[users[index].documentID] == true);
                      } else {
                        return Container();
                      } // This will build a list of Text widgets with the values from the List<String> that is stored in the streambuilder snapshot
                    },
                    itemCount: users.length);
          }),
    );
  }

  Widget userTab(
      String uid, String name, String imageURL, bool request, bool sent) {
    return Card(
      child: Row(children: <Widget>[
        Container(
          width: 50.0,
          height: 50.0,
          margin: EdgeInsets.all(5.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              fit: BoxFit.cover,
              image: NetworkImage(imageURL),
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
                    text: name,
                    style: TextStyle(fontSize: 20.0, color: Colors.black),
                  ),
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 10.0),
            ),
          ),
        ),
        request && !sent
            ? Column(
                children: <Widget>[
                  Container(
                    child: Text(
                      "Request Received",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    padding: EdgeInsets.only(right: 18, top: 5.0),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 80.0,
                        child: RaisedButton(
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                          ),
                          color: Colors.green,
                          elevation: 3.0,
                          onPressed: () {
                            confirmFriendRequest(uid);
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        padding: EdgeInsets.only(right: 10),
                      ),
                      Container(
                        width: 80.0,
                        child: RaisedButton(
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                          color: Colors.red,
                          elevation: 3.0,
                          onPressed: () {
                            sendFriendRequest(uid);
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        padding: EdgeInsets.only(right: 15),
                      ),
                    ],
                  )
                ],
              )
            : Container(
                child: ButtonTheme(
                  child: RaisedButton(
                    child: Icon(
                      sent ? Icons.check : Icons.add,
                      color: Colors.white,
                    ),
                    color: Colors.green,
                    elevation: 3.0,
                    onPressed: sent
                        ? null
                        : () {
                            sendFriendRequest(uid);
                          },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
                padding: EdgeInsets.only(right: 15.0, left: 15.0),
              ),
      ]),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(40.0),
      ),
      margin: EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
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
