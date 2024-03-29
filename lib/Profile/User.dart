import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Utils/DisplayTools.dart';
import 'package:pearawards/Utils/Utils.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;

class User {
  User({this.displayName, this.imageUrl, this.uid});
  String imageUrl;
  String displayName;
  String uid;
  int lastUpdated;
}

class UserTab extends StatefulWidget {
  UserTab({this.uid, this.user, this.onPressed});
  final String uid;
  final User user;
  final Function onPressed;

  @override
  State<StatefulWidget> createState() {
    return UserTabState(getUserFromUID(uid));
  }
}

class UserTabState extends State<UserTab> {
  UserTabState(Future<User> userFetch) {
    if (mounted) {
      if (widget.user == null) {
        loadUser(userFetch);
      } else {
        user = widget.user;
      }
    }
  }
  User user;
  bool loaded = false;
  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      user = widget.user;
    }
  }

  loadUser(Future<User> userFetch) async {
    user = await userFetch;
    loaded = true;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      loadUser(getUserFromUID(widget.uid));
    }
    return Container(
      height: 70,
      child: RaisedButton(
          onPressed: () {
            widget.onPressed();
          },
          child: Padding(
            child: Row(children: <Widget>[
              AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  alignment: Alignment.center,
                  child: user != null &&
                          (user.imageUrl == null || user.imageUrl == "")
                      ? Text(user.displayName[0],
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 40))
                      : Container(),
                      padding: EdgeInsets.symmetric(vertical: 8),
                  decoration: user != null &&
                          user.imageUrl != null &&
                          user.imageUrl != ""
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: NetworkImage(user.imageUrl),
                          ),
                        )
                      : BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.uid != null ? colorFromID(widget.uid) : globals.theme.primaryColor),
                ),
              ),
              Expanded(
                child: Container(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: RichText(
                      text: TextSpan(
                        text: user == null ? "loading..." : user.displayName,
                        style: TextStyle(
                            fontSize: 20, color: globals.theme.textColor),
                      ),
                    ),
                  ),
                  //padding: EdgeInsets.symmetric(horizontal: 5.0),
                ),
              ),
            ]),
            padding: EdgeInsets.symmetric(vertical: 5.0),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: globals.theme.cardColor),
      padding: EdgeInsets.only(top: 8.0,left: 8.0,right: 8.0),
    );
  }
}

StreamBuilder<QuerySnapshot> userStream(String searchString) {
  var stream = Firestore.instance
      .collection('users')
      .where('display_insensitive',
          isGreaterThanOrEqualTo: searchString.toUpperCase())
      .where('display_insensitive',
          isLessThan: incrementString(searchString.toUpperCase()))
      .snapshots();
  return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        var data = snapshot.data;
        List<DocumentSnapshot> users = [];
        if (data != null) {
          users = snapshot.data.documents;
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return UserTab(
                onPressed: () {
                  visitUserPage(users[index].documentID, context);
                },
                uid: users[index].documentID,
                user: User(
                    displayName: users[index].data['display'],
                    imageUrl: users[index].data['image'],
                    uid: users[index].documentID));
          }, childCount: users.length),
        );
      });
}
