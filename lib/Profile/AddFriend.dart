import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Utils/DisplayTools.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;
import 'package:pearawards/Utils/Upload.dart';
import 'package:pearawards/Utils/Utils.dart';
import 'User.dart';

Map<String, bool> justFollowed;
//Map sentRequests;

class AddFriend extends StatefulWidget {
  AddFriend({Key key, this.document, this.title, this.following})
      : super(key: key);

  final DocumentReference document;
  final String title;
  final List following;

  @override
  _AddFriendState createState() => _AddFriendState();
}

class _AddFriendState extends State<AddFriend> {
  List<User> users = [];
  bool mostRecent = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    justFollowed = {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: globals.theme.primaryColor,
          leading: IconButton(
            icon: Icon(Icons.close, size: 30),
            onPressed: () {
              Navigator.pop(context, false);
            },
          ),
          title: Text('Recommendations'),
        ),
        backgroundColor: globals.theme.backgroundColor,
        body: StreamBuilder(
            stream: Firestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              var data = snapshot.data;
              List<DocumentSnapshot> users = [];
              if (data != null) {
                users = snapshot.data.documents;
              }
              return widget.following == null
                  ? Container()
                  : ListView.builder(
                      itemBuilder: (BuildContext context, int index) {
                        if ((widget.following
                                        .indexOf(users[index].documentID) ==
                                    -1 ||
                                justFollowed[users[index].documentID] ==
                                    true) &&
                            users[index].documentID != globals.me.uid) {
                          return userTab(
                              users[index].documentID,
                              users[index].data['display'],
                              users[index].data['image']);
                        } else {
                          return Container();
                        } // This will build a list of Text widgets with the values from the List<String> that is stored in the streambuilder snapshot
                      },
                      itemCount: users.length);
            }));
  }

  Widget userTab(
    String uid,
    String name,
    String imageURL,
  ) {
    return Card(
      child: Container(
        child: Row(children: <Widget>[
          Container(
            alignment: Alignment.center,
            width: 50.0,
            height: 50.0,
            margin: EdgeInsets.all(5.0),
            child: imageURL == null || imageURL == ""
                ? Text(name[0],
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 40))
                : Container(),
            decoration: imageURL == null || imageURL == ""
                ? BoxDecoration(
                    shape: BoxShape.circle, color: uid != null ? colorFromID(uid) : globals.theme.primaryColor)
                : BoxDecoration(
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
          Container(
            child: ButtonTheme(
              child: RaisedButton(
                child: Icon(
                  widget.following.indexOf(uid) >= 0 ? Icons.check : Icons.add,
                  color: Colors.white,
                ),
                color: globals.theme.primaryColor,
                elevation: 3.0,
                onPressed: () {
                  sendFollowRequest(uid);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
            ),
            padding: EdgeInsets.only(right: 15.0, left: 15.0),
          ),
        ]),
        height: 60.0,
      ),
      margin: EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
    );
  }

  Future<void> sendFollowRequest(String uid) async {
    setState(() {});
    if (globals.followRequests[uid] != null) {
      globals.followRequests.remove(uid);
    } else {
      globals.followRequests[uid] =
          widget.following.indexOf(uid) >= 0 ? false : true;
    }
    if (widget.following.indexOf(uid) >= 0) {
      widget.following.remove(uid);
    } else {
      justFollowed[uid] = true;
      widget.following.add(uid);
    }
    massUploadFollows();
    setState(() {});
  }
}

cancelFriendRequest(String uid) async {}
