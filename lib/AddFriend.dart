import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Upload.dart';
import 'Award.dart';
import 'CustomPainters.dart';
import 'Globals.dart' as globals;
import 'ProfilePage.dart';

List<User> users = [];

class AddFriend extends StatefulWidget {
  AddFriend({Key key, this.document, this.title}) : super(key: key);

  final DocumentReference document;
  final String title;

  @override
  _AddFriendState createState() => _AddFriendState();
}

class _AddFriendState extends State<AddFriend> {
  bool mostRecent = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
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
            List<dynamic> users = [];
            if (data != null) {
              users = snapshot.data.documents;
            }
            return ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                if (users[index].documentID != globals.firebaseUser.uid) {
                  return Text(users[index].data["display"]);
                } // This will build a list of Text widgets with the values from the List<String> that is stored in the streambuilder snapshot
              },
              itemCount: users.length,
            );
          }),
    );
  }
}
