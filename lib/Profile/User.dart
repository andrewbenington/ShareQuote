import 'package:flutter/material.dart';

class User {
  User({this.displayName, this.imageUrl, this.uid});
  String imageUrl;
  String displayName;
  String uid;
  int lastUpdated;
}

class FriendTab extends StatelessWidget {
    FriendTab({this.friend, this.onPressed});
    final User friend;
    final Function onPressed;
    

  @override
  Widget build(BuildContext context) {
    return Padding(
      child: RaisedButton(
          onPressed: () {
            onPressed();
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          color: Colors.white),
      padding: EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
    );
  }
  }