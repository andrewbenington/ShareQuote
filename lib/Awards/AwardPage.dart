import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Utils/CustomPainters.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;
import 'Award.dart';

class AwardPage extends StatefulWidget {
  AwardPage({Key key, this.award, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final Award award;
  final String title;

  @override
  _AwardPageState createState() => _AwardPageState();
}

class _AwardPageState extends State<AwardPage> {
  TextEditingController commentController = TextEditingController();
  _AwardPageState();
  bool mostRecent = true;

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: globals.theme.primaryColor,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: StreamBuilder(
          stream: Firestore.instance
              .collection('${widget.award.docPath}/comments')
              .orderBy("timestamp")
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 0) {
                      return buildSingleAwardCard(context, widget.award);
                    } else {
                      Map data = snapshot.data.documents[index - 1].data;

                      return Comment(
                          message: data["message"],
                          uid: data["user"],
                          time: data["time"]);
                    } // This will build a list of Text widgets with the values from the List<String> that is stored in the streambuilder snapshot
                  },
                  itemCount: snapshot.data.documents.length == 0
                      ? 1
                      : snapshot.data.documents.length + 1);
            } else {
              return ListView();
            }
          }),
      /*ListView(
        children: <Widget>[
          buildAwardCard(context, widget.award, false),
          Card(
            child: Padding(
              padding: EdgeInsets.only(left: 8.0, right: 8.0),
              child: TextFormField(
                controller: commentController,
                decoration: InputDecoration(hintText: "Comment"),
                minLines: 1,
                maxLines: 6,
                textInputAction: TextInputAction.send,
                onFieldSubmitted: (message) {
                  commentController.clear();
                  postComment(message,
                      Firestore.instance.document(widget.award.docPath));
                },
              ),
            ),
            margin: EdgeInsets.only(left: 5.0, right: 5.0, top: 5),
          ),
        ],
      ),*/
      backgroundColor: globals.theme.backgroundColor,
    );
  }

  Widget buildSingleAwardCard(BuildContext context, Award award) {
    return Card(
      color: globals.theme.cardColor,
      child: CustomPaint(
        painter: TabPainter(
            fromLeft: 0.4,
            height: 36,
            color: award.fromDoc
                ? Colors.grey[300]
                : globals.theme.backgroundColor.withOpacity(0.5)),
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(left: 15.0, right: 15.0, bottom: 10.0),
              child: award,
            ),
            Container(
              color: globals.theme.backgroundColor.withOpacity(0.5),
              padding: EdgeInsets.only(left: 8.0, right: 8.0),
              child: TextFormField(
                autocorrect: false,
                controller: commentController,
                decoration: InputDecoration(
                    hintText: "Comment",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: globals.theme.backTextColor)),
                minLines: 1,
                maxLines: 6,
                textInputAction: TextInputAction.send,
                onFieldSubmitted: (message) {
                  commentController.clear();
                  postComment(message,
                      Firestore.instance.document(widget.award.docPath));
                },
              ),
            ),
          ],
        ),
      ),
      margin: EdgeInsets.only(left: 5.0, right: 5.0, top: 5),
    );
  }

  postComment(String message, DocumentReference award) async {
    award
        .collection("comments")
        .document(globals.me.uid +
            DateTime.now().microsecondsSinceEpoch.toString())
        .setData({
      "message": message,
      "user": globals.me.uid,
      "timestamp": DateTime.now().microsecondsSinceEpoch
    });
    widget.award.comments++;
    globals.loadedAwards[widget.award.hash].comments = widget.award.comments;
  }
}

class Comment extends StatefulWidget {
  Comment({this.uid, this.message, this.time});
  final String uid;
  final String message;
  final int time;
  @override
  State<StatefulWidget> createState() {
    return CommentState();
  }
}

class CommentState extends State<Comment> {
  CommentState();
  bool loadedURL = false;
  String imageURL;
  String name = "";
  NetworkImage image;
  @override
  void initState() {
    super.initState();
    loadURL();
  }

  loadURL() async {
    DocumentSnapshot snap =
        await Firestore.instance.document('users/${widget.uid}').get();
    globals.reads++;
    imageURL = snap.data["image"];
    name = snap.data["display"];
    loadedURL = true;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: globals.theme.cardColor,
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            alignment: Alignment.topCenter,
            color: globals.theme.lightPrimary,
            child: Padding(
                padding: EdgeInsets.all(5),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: loadedURL
                      ? BoxDecoration(
                          image: DecorationImage(
                              image: NetworkImage(
                                imageURL,
                              ),
                              fit: BoxFit.cover),
                          shape: BoxShape.circle,
                        )
                      : BoxDecoration(
                          color: globals.theme.backgroundColor,
                          shape: BoxShape.circle,
                        ),
                )),
          ),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding:
                    EdgeInsets.only(left: 10.0, right: 5.0, top: 5, bottom: 2),
                child: Text(
                  name,
                  overflow: TextOverflow.fade,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: globals.theme.textColor),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 10.0, right: 5.0, bottom: 5),
                child: Text(
                  widget.message,
                  overflow: TextOverflow.fade,
                  style:
                      TextStyle(fontSize: 16, color: globals.theme.textColor),
                ),
              )
            ]),
          )
        ]),
      ),
      margin: EdgeInsets.only(left: 5.0, right: 5.0, top: 5),
    );
  }
}
