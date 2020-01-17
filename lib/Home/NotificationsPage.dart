import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Awards/Award.dart';
import 'package:pearawards/Awards/AwardPage.dart';
import 'package:pearawards/Utils/DisplayTools.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;

class NotificationsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return NotificationsPageState();
  }
}

class NotificationsPageState extends State<NotificationsPage> {
  Map friends;
  initState() {
    super.initState();
    loadFriends();
  }

  loadFriends() async {
    friends = (await Firestore.instance
            .document('users/${globals.firebaseUser.uid}')
            .get())
        .data['friends'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance
            .collection('users')
            .document(globals.firebaseUser.uid)
            .collection('notifications')
            .orderBy("time", descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return CircularProgressIndicator();
            default:
              return new ListView.separated(
                  separatorBuilder: (context, index) => Divider(
                        color: Colors.black,
                      ),
                  itemCount: snapshot.data.documents.length,
                  itemBuilder: (context, index) {
                    if (snapshot.data.documents[index].data["read"] != true) {
                      snapshot.data.documents[index].reference
                          .updateData({"read": true});
                    }
                    return notificationTile(
                        snapshot.data.documents[index].data);
                  });
          }
        },
      ),
    );
  }

  ListTile notificationTile(Map data) {
    Map<int, String> messages = {
      0: '${data['name']} liked an award you gave',
      1: '${data['name']} commented on an award you gave',
      2: '${data['name']} gave you an award!',
      3: 'Friend request from ${data['name']}',
      4: '${data['name']} accepted your friend request',
      5: '${data['name']} liked an award you received',
      6: '${data['name']} commented on an award you received'
    };
    if (data['notification'] != 3) {
      return ListTile(
          title: Text(
            messages[data['notification']],
            style: TextStyle(
                fontWeight:
                    data["read"] == true ? FontWeight.normal : FontWeight.bold),
          ),
          subtitle: data['time'] is int
              ? Text(
                  formatDateTimeComplete(
                      DateTime.fromMicrosecondsSinceEpoch(data['time'])),
                  style: TextStyle(
                      fontWeight: data["read"] == true
                          ? FontWeight.normal
                          : FontWeight.bold),
                )
              : Text(""),
          onTap: () {
            loadAndVisitAward(data['award']);
          },
          trailing: Icon(Icons.bookmark));
    } else {
      return ListTile(
          title: Text(
            'Friend request from ${data['name']}',
            style: TextStyle(
                fontWeight:
                    data["read"] == true ? FontWeight.normal : FontWeight.bold),
          ),
          trailing: friends[data["uid"]] == false
              ? Column(
                  children: <Widget>[
                    Container(
                      child: Text(
                        'Request Received',
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
                              confirmFriendRequest(data["uid"]);
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
                              cancelFriendRequest(data["uid"]);
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
              : friends[data["uid"]] == true
                  ? Container(
                      child: ButtonTheme(
                        child: RaisedButton(
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                          ),
                          color: Colors.green,
                          elevation: 3.0,
                          onPressed: null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                      ),
                      padding: EdgeInsets.only(right: 15.0, left: 15.0),
                    )
                  : Text("oops"));
    }
  }

  confirmFriendRequest(String uid) async {
    DocumentReference me = Firestore.instance
        .collection('users')
        .document(globals.firebaseUser.uid);
    DocumentReference them =
        Firestore.instance.collection('users').document(uid);
    if ((await them.get()).data['friends'] == null) {
      them.setData({
        'friends': {globals.firebaseUser.uid: true}
      }, merge: true);
      them.updateData({
        'sentRequests.${globals.firebaseUser.uid}': null,
        'lastNotification': DateTime.now().microsecondsSinceEpoch
      });
    } else {
      them.updateData({
        'friends.${globals.firebaseUser.uid}': true,
        'sentRequests.${globals.firebaseUser.uid}': null,
        'lastNotification': DateTime.now().microsecondsSinceEpoch
      });
    }

    me.updateData({
      'friends.$uid': true,
      'sentRequests.$uid': null,
      'lastNotification': DateTime.now().microsecondsSinceEpoch
    });
    loadFriends();
  }

  cancelFriendRequest(String uid) async {}

  loadAndVisitAward(DocumentReference ref) async {
    DocumentSnapshot doc = await ref.get();
    AwardLoader loader = AwardLoader(
      snap: doc,
      refresh: () {},
    );
    await loader.loadAward();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AwardPage(
            award: loader.award,
            title: loader.award.author.name +
                (loader.award.showYear
                    ? ''
                    : ', ${formatDateTimeAward(DateTime.fromMicrosecondsSinceEpoch(loader.award.timestamp))}')),
      ),
    );
  }
}
