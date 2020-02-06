import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Assets/ExtraIcons.dart';
import 'package:pearawards/Awards/Award.dart';
import 'package:pearawards/Awards/AwardPage.dart';
import 'package:pearawards/Collections/Collection.dart';
import 'package:pearawards/Collections/CollectionFunctions.dart';
import 'package:pearawards/Profile/ProfilePage.dart';
import 'package:pearawards/Utils/DisplayTools.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;
import 'package:pearawards/Utils/Utils.dart';

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
        title: Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance
            .collection(
                'users_private/${globals.firebaseUser.uid}/notifications')
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
      3: '${data['name']} followed you',
      4: '${data['name']} invited you to join the collection \'${data['title']}\'',
      5: '${data['name']} liked an award you received',
      6: '${data['name']} commented on an award you received'
    };
    Map<int, Icon> icons = {
      0: Icon(ExtraIcons.heart),
      1: Icon(ExtraIcons.comment),
      2: Icon(Icons.bookmark),
      3: Icon(Icons.person),
      4: Icon(Icons.collections_bookmark),
      5: Icon(ExtraIcons.heart),
      6: Icon(ExtraIcons.comment)
    };

    Map<int, Function> functions = {
      3: () {
        visitUserPage(data['uid'], context);
        
      },
      4: () async {
        DocumentSnapshot document =
            await Firestore.instance.document(data['path']).get();
        if (!document.exists) {
          Firestore.instance.document(data['path']).delete();
          globals.loadedCollections.remove(document.documentID);
          return;
        }
        Collection c = Collection(
            docRef: document.reference,
            title: document.data['name'],
            owner: document.data['owner'],
            lastEdited: document.data['lastEdit']);
        pushCollectionStream(context, c, () {});
      }
    };
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
        onTap: functions[data['notification']] != null
            ? functions[data['notification']]
            : () {
                loadAndVisitAward(Firestore.instance.document(data['award']));
              },
        trailing: icons[data['notification']]);
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
  }

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
