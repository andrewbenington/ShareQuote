import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;

class NotificationsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return NotificationsPageState();
  }
}

class NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance
            .collection("users")
            .document(globals.firebaseUser.uid)
            .collection("notifications")
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return CircularProgressIndicator();
            default:
              return new ListView(
                  children:
                      snapshot.data.documents.map((DocumentSnapshot document) {
                if (document["notification"] == 3) {
                  return ListTile(
                      title: Text("Friend request from " + document["name"]));
                } else {
                  return ListTile(
                      title: Text("Notification " + document["notification"]));
                }
              }).toList());
          }
        },
      ),
    );
  }
}
