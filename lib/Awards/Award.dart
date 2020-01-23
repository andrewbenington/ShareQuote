import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:pearawards/Assets/ExtraIcons.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Awards/TagUser.dart';
import 'package:pearawards/Utils/Converter.dart';
import 'package:pearawards/Utils/DisplayTools.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;
import 'package:pearawards/Utils/Upload.dart';
import 'package:pearawards/Utils/Utils.dart';

import 'AwardPage.dart';
import 'package:pearawards/Utils/CustomPainters.dart';

enum Difference { different, same, edited }

class Document {
  Document({this.name, this.url, this.awards});
  final String url;
  final String name;
  List<Award> awards;
}

class AwardLoader {
  AwardLoader(
      {this.pointer,
      this.snap,
      this.reference,
      this.award,
      this.numLoaded,
      this.lastEdit,
      this.refresh,
      this.downloaded}) {
    if (award != null) {
      isLoaded = true;
      award.refresh = refresh;
    } else if (snap != null) {
      awardFromSnapshot(snap);
      isLoaded = true;
      award.refresh = refresh;
    } else if (lastEdit != null &&
        globals.loadedAwards[reference.documentID] != null &&
        globals.loadedAwards[reference.documentID].lastLoaded > lastEdit) {
      award = globals.loadedAwards[reference.documentID];
      isLoaded = true;
      award.refresh = refresh;
    }
  }
  final DocumentReference pointer;
  final DocumentSnapshot snap;
  final DocumentReference reference;
  final PrimitiveWrapper numLoaded;
  final PrimitiveWrapper downloaded;
  final Function refresh;
  final int lastEdit;
  Award award;
  bool isLoaded = false;

  Future<void> loadAward() async {
    if (isLoaded) {
      if (numLoaded != null) {
        numLoaded.value++;
      }
      return;
    }
    await reference.get().then((doc) {
      if (pointer != null && !awardFromSnapshot(doc)) {
        pointer.delete();
      }
      isLoaded = true;
      if (numLoaded != null) {
        numLoaded.value++;
      }
      if (downloaded != null) {
        downloaded.value++;
      }
    });
  }

  bool awardFromSnapshot(DocumentSnapshot doc) {
    if (doc.exists) {
      award = Award.fromMap(doc.data);
      award.likes = doc.data['likes'];
      award.refresh = refresh;
      award.timestamp = doc.data['timestamp'];
      award.docPath = doc.reference.path;
      award.lastLoaded = DateTime.now().microsecondsSinceEpoch;
      globals.loadedAwards[award.hash.toString()] = award;
      return true;
    } else {
      return false;
    }
  }

  Widget buildCard(BuildContext context, bool tappable, bool filter) {
    if (filter &&
        (!isLoaded ||
            !award
                .excludesPattern('poo|fuck|Jesus|God|dick|shit|fleshlight'))) {
      return Container();
    }
    return AwardCard(
      award: award,
      tappable: tappable,
    );
  }
}

class AwardCard extends StatefulWidget {
  AwardCard({this.award, this.tappable = true});
  @override
  State<StatefulWidget> createState() {
    return _AwardCardState();
  }

  final Award award;
  final bool tappable;
}

class _AwardCardState extends State<AwardCard> {

  @override
  Widget build(BuildContext context) {
    return Card(
      child: CustomPaint(
        painter: TabPainter(
            fromLeft: 0.4,
            height: 36,
            color: widget.award.fromDoc ? Colors.grey[300] : Colors.green[100]),
        child: FlatButton(
          splashColor: Colors.transparent,
          //highlightColor: Colors.transparent,
          onPressed: widget.tappable
              ? () {
                  DateTime time = DateTime.fromMicrosecondsSinceEpoch(
                      widget.award.timestamp);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AwardPage(
                          award: widget.award,
                          title: widget.award.author.name +
                              (widget.award.showYear
                                  ? ''
                                  : ', ${formatDateTimeAward(time)}')),
                    ),
                  );
                }
              : null,
          child: Column(
            children: [
              widget.award,
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    child: IconButton(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      icon: Icon(
                        widget.award.liked
                            ? ExtraIcons.heart
                            : ExtraIcons.heart_empty,
                        color: Colors.green[600],
                      ),
                      onPressed: () {
                        if (!widget.award.liked) {
                          if (globals.likeRequests[widget.award.docPath] ==
                              false) {
                            globals.likeRequests.remove(widget.award.docPath);
                          } else {
                            globals.likeRequests[widget.award.docPath] = true;
                            massUploadLikes();
                          }
                          widget.award.liked = true;
                          widget.award.likes += 1;
                        } else if (widget.award.liked) {
                          if (globals.likeRequests[widget.award.docPath] ==
                              true) {
                            globals.likeRequests.remove(widget.award.docPath);
                          } else {
                            globals.likeRequests[widget.award.docPath] = false;
                            massUploadLikes();
                          }
                          widget.award.liked = false;
                          widget.award.likes -= 1;
                        }
                        setState(() {});
                      },
                    ),
                    width: 38,
                  ),
                  Container(
                    width: 30,
                    child: Text(
                      widget.award.likes.toString(),
                      style: TextStyle(fontSize: 18, color: Colors.green[600]),
                    ),
                  ),
                  Container(
                    child: Icon(
                      ExtraIcons.comment_empty,
                      color: Colors.green[600],
                    ),
                    width: 38,
                    padding: EdgeInsets.only(bottom: 4),
                  ),
                  Padding(
                    child: Text(
                      widget.award.likes.toString(),
                      style: TextStyle(fontSize: 18, color: Colors.green[600]),
                    ),
                    padding: EdgeInsets.only(right: 22),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      margin: EdgeInsets.only(left: 5.0, right: 5.0, top: 5),
    );
  }
}

Widget buildAwardCard(BuildContext context, Award award, bool tappable) {
  return Card(
    child: CustomPaint(
      painter: TabPainter(
          fromLeft: 0.4,
          height: 36,
          color: award.fromDoc ? Colors.grey[300] : Colors.green[100]),
      child: FlatButton(
        splashColor: Colors.transparent,
        //highlightColor: Colors.transparent,
        onPressed: tappable
            ? () {
                DateTime time =
                    DateTime.fromMicrosecondsSinceEpoch(award.timestamp);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AwardPage(
                        award: award,
                        title: award.author.name +
                            (award.showYear
                                ? ''
                                : ', ${formatDateTimeAward(time)}')),
                  ),
                );
              }
            : null,
        child: award,
      ),
    ),
    margin: EdgeInsets.only(left: 5.0, right: 5.0, top: 5),
  );
}

class Award extends StatelessWidget {
  Award(
      {this.quotes,
      this.timestamp,
      this.numQuotes,
      this.author,
      this.fromDoc = false,
      this.showYear = false,
      this.nsfw = false,
      this.liked = false,
      this.docPath}) {
    for (Line l in quotes) {
      hash ^= l.getHash();
    }
  }
  factory Award.fromMap(Map<String, dynamic> map) {
    List q = map['lines'];
    if (q.length == 0) {
      return null;
    }
    return Award(
      fromDoc: map['fromdoc'],
      showYear: map['showYear'],
      timestamp: map['timestamp'],
      quotes: q.map(
        (quote) {
          return Line.fromMap(quote);
        },
      ).toList(),
      numQuotes: map['lines'].length,
      author: Name.fromMap(
        map['author'],
      ),
      nsfw: map['nsfw'],
      docPath: map['docPath'],
    );
  }

  int timestamp;
  final int numQuotes;
  final Name author;
  final List<Line> quotes;
  final bool fromDoc;
  bool nsfw;
  bool showYear;
  bool liked;
  String docPath;
  int likes = 0;
  int hash = 0;
  int lastLoaded = 0;
  Function refresh;

  bool contains(String filter) {
    for (Line l in quotes) {
      if (l.message.toLowerCase().contains(filter.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  bool excludesPattern(String pattern) {
    RegExp expression = RegExp(pattern, caseSensitive: false, unicode: true);
    for (Line l in quotes) {
      if (expression.hasMatch(l.message)) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
      children: [
        Align(
          child: Stack(
            children: <Widget>[
              FractionallySizedBox(
                widthFactor: 0.32,
                child: Container(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: RichText(
                      text: TextSpan(
                        text: showYear
                            ? DateTime.fromMicrosecondsSinceEpoch(timestamp)
                                .year
                                .toString()
                            : formatDateTimeShort(
                                DateTime.fromMicrosecondsSinceEpoch(timestamp)),
                        style: TextStyle(
                            fontSize: 17.0,
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  margin: EdgeInsets.only(bottom: 15.0, top: 8.0),
                  alignment: Alignment.center,
                ),
              ),
              Align(
                child: FractionallySizedBox(
                  widthFactor: 0.65,
                  child: Row(children: <Widget>[
                    Expanded(
                      child: Container(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: RichText(
                            text: TextSpan(
                              text: author == null
                                  ? ''
                                  : fromDoc ? 'Google Doc' : author.name,
                              style: TextStyle(
                                  fontSize: 17.0,
                                  color: fromDoc
                                      ? Colors.grey[700]
                                      : Colors.green[800],
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        margin: EdgeInsets.only(bottom: 15.0, top: 8.0),
                        alignment: Alignment.centerRight,
                      ),
                    ),
                  ]),
                ),
                alignment:
                    fromDoc ? Alignment(0.55, 0.0) : Alignment.centerRight,
              ),
              Align(
                child: fromDoc
                    ? Padding(
                        child: Icon(
                          Icons.subject,
                          color: Colors.grey[700],
                        ),
                        padding: EdgeInsets.only(left: 8, top: 6.0))
                    : Container(),
                alignment: Alignment.centerRight,
              ),
            ],
          ),
        ),
        Column(
          children: quotes,
        ),
      ],
    ));
  }
}

abstract class Line extends StatelessWidget {
  Line(String m) : message = m;
  final String message;
  factory Line.fromMap(Map map) {
    if (map['name'] == null) {
      return Context.fromMap(map);
    } else {
      return Quote.fromMap(map);
    }
  }

  @override
  Widget build(BuildContext context);
  bool isQuote();
  int getHash();
}

class Quote extends Line {
  Quote({this.message, this.name}) : super(message);

  factory Quote.fromMap(Map map) {
    return Quote(
      message: map['quote'],
      name: Name.fromMap(map['name']),
    );
  }
  final String message;
  final Name name;

  bool isQuote() {
    return true;
  }

  int getHash() {
    return name != null
        ? message.hashCode * 1000000000 + name.name.hashCode
        : message.hashCode;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Align(
          child: Container(
            child: RichText(
              text: TextSpan(
                text: '\"$message\"',
                style: TextStyle(
                  fontSize: 20.0,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          alignment: Alignment.centerLeft,
        ),
        name == null ? Container() : name
      ],
    );
  }
}

class Context extends Line {
  Context({this.message}) : super(message);

  factory Context.fromMap(Map map) {
    return Context(
      message: map['context'],
    );
  }
  final String message;

  bool isQuote() {
    return false;
  }

  int getHash() {
    return message.hashCode;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Center(
          child: Container(
            child: RichText(
              text: TextSpan(
                text: '*$message*',
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            margin: EdgeInsets.symmetric(vertical: 10.0),
          ),
        ),
      ],
    );
  }
}

class Name extends StatelessWidget {
  Name({this.name, this.uid});

  factory Name.fromMap(Map map) {
    return Name(
      name: map['name'],
      uid: map['uid'],
    );
  }
  String name;
  String uid;

  tagUser(BuildContext context) async {
    Award a = context.findAncestorWidgetOfExactType<Award>();
    uid = await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => TagUser(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
                scale: animation.drive(CurveTween(curve: Curves.ease)),
                alignment: Alignment.center,
                child: child);
          },
        ));
    if (uid != null) {
      DocumentReference recipient = Firestore.instance.document('users/$uid');
      Firestore.instance.document(a.docPath).updateData(awardToMap(a));
      recipient.collection('awards').document(a.hash.toString()).setData({
        'timestamp': a.timestamp,
        'reference': Firestore.instance.document(
            'users/${a.author.uid}/created_awards/${a.hash.toString()}')
      });
      sendNotification(uid, {
        'notification': '2',
        'name': globals.firebaseUser.displayName,
        'uid': globals.firebaseUser.uid,
        'award': a.docPath,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      child: FlatButton(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          child: RichText(
            text: TextSpan(
              text: '- $name',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: uid == null ? FontWeight.normal : FontWeight.bold,
                color: uid == null ? Colors.black87 : Colors.black,
              ),
            ),
          ),
          margin: EdgeInsets.only(bottom: 8.0),
        ),
        onPressed: uid == null
            ? () {
                tagUser(context);
              }
            : () {
                visitUserPage(uid, context);
              },
      ),
      alignment: Alignment.centerRight,
    );
  }
}

/*Difference isDifferent(Award award1, Award award2) {
  for (Line l1 in award1.quotes) {
    for (Line l2 in award2.quotes) {
      double diff = StringSimilarity.compareTwoStrings(l1.message, l2.message);
      if (diff > 0.6) {
        return Difference.edited;
      }
    }
  }
  return Difference.different;
}
*/
