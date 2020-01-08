import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Awards/TagUser.dart';
import 'package:pearawards/Profile/ProfilePage.dart';
import 'package:pearawards/Profile/User.dart';
import 'package:pearawards/Utils/Converter.dart';
import 'package:pearawards/Utils/DisplayTools.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;
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
  AwardLoader(this.pointer, this.reference, this.award, this.loaded) {
    if (award != null) {
      isLoaded = true;
    }
  }
  final DocumentReference pointer;
  final DocumentReference reference;
  final PrimitiveWrapper loaded;
  Award award;
  bool isLoaded = false;

  Future<void> loadAward() async {
    await reference.get().then((doc) {
      if (doc.exists) {
        award = Award.fromJson(jsonDecode(doc.data['json']));
        award.likes = doc.data['likes'];
        award.timestamp = doc.data['timestamp'];
        award.docPath = doc.reference.path;
        isLoaded = true;
        loaded.value++;
      } else {
        pointer.delete();
      }
    });
  }

  Widget buildCard(BuildContext context, bool tappable) {
    if (!isLoaded ||
        !award.excludesPattern('poo|fuck|Jesus|God|dick|shit|fleshlight')) {
      return Container();
    }
    return buildAwardCard(context, award, tappable);
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
                                : ' ${formatDateTimeAward(time)}')),
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
      this.docPath}) {
    for (Line l in quotes) {
      hash ^= l.getHash();
    }
  }
  factory Award.fromJson(Map<String, dynamic> jsonMap) {
    List q = jsonMap['lines'];
    if (q.length == 0) {
      return null;
    }
    return Award(
      fromDoc: jsonMap['fromdoc'],
      showYear: jsonMap['showYear'],
      timestamp: jsonMap['timestamp'],
      quotes: q
          .map(
            (quote) => Line.fromJson(
              quote,
            ),
          )
          .toList(),
      numQuotes: jsonMap['lines'].length,
      author: Name.fromJson(
        jsonMap['author'],
      ),
      nsfw: jsonMap['nsfw'],
      docPath: jsonMap['docPath'],
    );
  }

  int timestamp;
  final int numQuotes;
  final Name author;
  final List<Line> quotes;
  final bool fromDoc;
  bool nsfw;
  bool showYear;
  String docPath;
  int likes = 0;
  int hash = 0;

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
        Text(likes == 0 ? 'like' : likes.toString())
      ],
    ));
  }
}

abstract class Line extends StatelessWidget {
  Line(String m) : message = m;
  final String message;
  factory Line.fromJson(Map<String, dynamic> jsonMap) {
    if (jsonMap['name'] == null) {
      return Context.fromJson(jsonMap);
    } else {
      return Quote.fromJson(jsonMap);
    }
  }

  @override
  Widget build(BuildContext context);
  bool isQuote();
  int getHash();
}

class Quote extends Line {
  Quote({this.message, this.name}) : super(message);

  factory Quote.fromJson(Map<String, dynamic> jsonMap) {
    return Quote(
      message: jsonMap['quote'],
      name: Name.fromJson(jsonMap['name']),
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

  factory Context.fromJson(Map<String, dynamic> jsonMap) {
    return Context(
      message: jsonMap['context'],
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

  factory Name.fromJson(Map<String, dynamic> jsonMap) {
    return Name(
      name: jsonMap['name'],
      uid: jsonMap['uid'],
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
      Firestore.instance
          .document(a.docPath)
          .updateData({'json': jsonEncode(awardToJson(a))});
      Firestore.instance
          .collection('users/$uid/awards')
          .document(a.hash.toString())
          .setData({
        'timestamp': a.timestamp,
        'reference': Firestore.instance.document(
            'users/${a.author.uid}/created_awards/${a.hash.toString()}')
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      child: FlatButton(
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
                Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          Scaffold(
                              appBar: AppBar(),
                              body: ProfilePage(
                                  User(displayName: name, uid: uid))),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return ScaleTransition(
                            scale:
                                animation.drive(CurveTween(curve: Curves.ease)),
                            alignment: Alignment.center,
                            child: child);
                      },
                    ));
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
