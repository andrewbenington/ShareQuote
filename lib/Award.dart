import 'package:flutter/material.dart';

import 'AwardPage.dart';
import 'CustomPainters.dart';
import 'Person.dart';

class Document {
  Document({this.name, this.url, this.awards});
  final String url;
  final String name;
  List<Award> awards;
}

Widget buildAwardCard(BuildContext context, Award award, bool tappable) {
  return Card(
    child: CustomPaint(
      painter: TabPainter(),
      child: FlatButton(
        onPressed: tappable
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AwardPage(
                        award: award, title: award.year.toString() + " Award"),
                  ),
                );
              }
            : null,
        child: award,
      ),
    ),
    margin: EdgeInsets.all(5.0),
  );
}

class Award extends StatelessWidget {
  Award(
      {this.quotes,
      this.year,
      this.day,
      this.month,
      this.numQuotes,
      this.author,
      this.fromDoc = false});
  factory Award.fromJson(Map<String, dynamic> jsonMap) {
    List q = jsonMap["lines"];
    return Award(
        fromDoc: jsonMap["fromdoc"],
        year: jsonMap["year"],
        month: jsonMap["month"],
        day: jsonMap["day"],
        quotes: q
            .map(
              (quote) => Line.fromJson(
                quote,
              ),
            )
            .toList(),
        numQuotes: jsonMap["lines"].length,
        author: Name.fromJson(
          jsonMap["author"],
        ));
  }

  final int month;
  final int day;
  final int year;
  final int numQuotes;
  final Name author;
  final List<Line> quotes;
  final bool fromDoc;
  int likes = 0;

  bool contains(String filter) {
    for (Line l in quotes) {
      if (l.message.toLowerCase().contains(filter.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
      children: [
        Align(
          child: Stack(
            children: <Widget>[
              Container(
                child: RichText(
                  text: TextSpan(
                    text: year.toString(),
                    style: TextStyle(
                        fontSize: 17.0,
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold),
                  ),
                ),
                margin: EdgeInsets.only(bottom: 15.0, top: 10.0),
                alignment: Alignment.centerLeft,
              ),
              Container(
                child: fromDoc
                    ? Icon(
                        Icons.subject,
                        color: Colors.grey[700],
                      )
                    : RichText(
                        text: TextSpan(
                          text: author == null ? "" : author.first,
                          style: TextStyle(
                              fontSize: 17.0,
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                alignment: Alignment.centerRight,
                margin: EdgeInsets.only(top: 8.0),
              ),
            ],
          ),
        ),
        Column(
          children: quotes,
        ),
        Text(likes == 0 ? "like" : likes.toString())
      ],
    ));
  }
}

abstract class Line extends StatelessWidget {
  Line(String m) : message = m;
  final String message;
  factory Line.fromJson(Map<String, dynamic> jsonMap) {
    if (jsonMap["name"] == null) {
      return Context.fromJson(jsonMap);
    } else {
      return Quote.fromJson(jsonMap);
    }
  }

  @override
  Widget build(BuildContext context);
  bool isQuote();
}

class Quote extends Line {
  Quote({this.message, this.name}) : super(message);

  factory Quote.fromJson(Map<String, dynamic> jsonMap) {
    return Quote(
      message: jsonMap["quote"],
      name: Name.fromJson(jsonMap["name"]),
    );
  }
  final String message;
  final Name name;

  bool isQuote() {
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Align(
          child: Container(
            child: RichText(
              text: TextSpan(
                text: "\"" + message + "\"",
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
      message: jsonMap["context"],
    );
  }
  final String message;

  bool isQuote() {
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Center(
          child: Container(
            child: RichText(
              text: TextSpan(
                text: "*" + message + "*",
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
  Name({this.first, this.last, this.uid});

  factory Name.fromJson(Map<String, dynamic> jsonMap) {
    return Name(
      first: jsonMap["first"],
      last: jsonMap["last"],
    );
  }
  final String first;
  final String last;
  final String uid;

  @override
  Widget build(BuildContext context) {
    return Align(
      child: FlatButton(
          child: Container(
            child: RichText(
              text: TextSpan(
                text: "- " + first + " " + last,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.black87,
                ),
              ),
            ),
            margin: EdgeInsets.only(bottom: 8.0),
          ),
          onPressed: null),
      alignment: Alignment.centerRight,
    );
  }
}
