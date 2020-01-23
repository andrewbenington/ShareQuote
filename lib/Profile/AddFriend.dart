import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;
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
  bool loading = false;

  @override
  void initState() {
    super.initState();
    justFollowed = {};
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
        title: Text('Recommendations'),
      ),
      backgroundColor: Colors.green[200],
      body: Stack(children: [
        StreamBuilder(
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
                            users[index].documentID !=
                                globals.firebaseUser.uid) {
                          return userTab(
                              users[index].documentID,
                              users[index].data['display'],
                              users[index].data['image']);
                        } else {
                          return Container();
                        } // This will build a list of Text widgets with the values from the List<String> that is stored in the streambuilder snapshot
                      },
                      itemCount: users.length);
            }),
        loading ? Center(child: CircularProgressIndicator()) : Container()
      ]),
    );
  }

  Widget userTab(
    String uid,
    String name,
    String imageURL,
  ) {
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
        Container(
          child: ButtonTheme(
            child: RaisedButton(
              child: Icon(
                justFollowed[uid] != null ? Icons.check : Icons.add,
                color: Colors.white,
              ),
              color: Colors.green,
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
      margin: EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
    );
  }

  Future<void> sendFollowRequest(String uid) async {
    loading = true;
    setState(() {});
    HttpsCallable post = CloudFunctions.instance
        .getHttpsCallable(functionName: "sendFollowRequest");
    var result = await post.call({
      "remove": widget.following.indexOf(globals.firebaseUser.uid) != 7
          ? "true"
          : "false",
      "from": globals.firebaseUser.uid,
      "name": globals.firebaseUser.displayName,
      "to": uid
    }).catchError((error) {
      print(error);
      loading = false;
      return;
    });
    if (widget.following.indexOf(uid) >= 0) {
      widget.following.remove(uid);
      justFollowed.remove(uid);
    } else {
      widget.following.add(uid);
      justFollowed[uid] = true;
    }
    loading = false;
    setState(() {});
    print(result.data);
  }
}

cancelFriendRequest(String uid) async {}
