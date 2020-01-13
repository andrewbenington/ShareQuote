import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widgets/flutter_widgets.dart';
import 'package:pearawards/Profile/User.dart';
import 'package:pearawards/Utils/Upload.dart';
import 'package:pearawards/Utils/Utils.dart';
import 'Award.dart';
import 'package:pearawards/Utils/CustomPainters.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;

List<NewLineForm> lines = [];
int editingIndex = 0;
String search = "";
String selectedUID = "";
Function reloadLineForm;

class AddQuote extends StatefulWidget {
  AddQuote({Key key, this.document, this.title}) : super(key: key);

  final DocumentReference document;
  final String title;

  @override
  _AddQuoteState createState() => _AddQuoteState();
}

class _AddQuoteState extends State<AddQuote> {
  bool mostRecent = true;
  String errorMessage = "";
  ItemScrollController scrollController = ItemScrollController();
  List<DocumentSnapshot> users = [];
  Map friends;

  @override
  void initState() {
    search = "";
    var newForm = NewLineForm(
        index: lines.length,
        scrollController: scrollController,
        searchForName: () {
          setState(() {});
        });
    newForm.remove = () {
      lines.remove(newForm);
      setState(() {});
    };
    lines.add(newForm);
    super.initState();
    lines = [newForm];
  }

  loadFriends() async {
    var me = await Firestore.instance
        .document('users/${globals.firebaseUser.uid}')
        .get();
    friends = me.data['friends'];
    if (friends == null) {
      friends = Map();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.check, size: 30),
                onPressed: () {
                  List<Quote> quotes = [];
                  for (NewLineForm form in lines) {
                    if (form.name != null && form.message != null) {
                      quotes.add(Quote(
                        message: form.message,
                        name: Name(
                          name: form.name,
                          uid: form.uid,
                        ),
                      ));
                    }
                  }
                  if (quotes.length > 0) {
                    Award a = Award(
                        quotes: quotes,
                        timestamp: DateTime.now().microsecondsSinceEpoch,
                        author: Name(
                          uid: globals.firebaseUser.uid,
                          name: globals.firebaseUser.displayName,
                        ));
                    uploadNewAward(
                        'users/${globals.firebaseUser.uid}/created_awards',
                        a,
                        widget.document,
                        true);
                    globals.loadedAwards[a.hash.toString()] = a;
                    Navigator.pop(context, a);
                  } else {
                    Navigator.pop(context, null);
                  }
                }),
          ],
          leading: IconButton(
            icon: Icon(Icons.close, size: 30),
            onPressed: () {
              Navigator.pop(context, null);
            },
          ),
          title: Text("Add Award"),
        ),
        backgroundColor: Colors.green[200],
        body: Column(children: <Widget>[
          Expanded(
              child: ScrollablePositionedList.builder(
                  physics: ClampingScrollPhysics(),
                  itemScrollController: scrollController,
                  itemCount: lines.length + 1,
                  itemBuilder: (context, index) {
                    return index == lines.length
                        ? Padding(
                            key: ValueKey("button"),
                            child: RaisedButton(
                              child: Text(
                                "Add Line",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              color: Colors.green,
                              elevation: 3.0,
                              onPressed: () {
                                var newForm = NewLineForm(
                                  index: lines.length,
                                  scrollController: scrollController,
                                  searchForName: () {
                                    setState(() {});
                                  },
                                );
                                newForm.remove = () {
                                  lines.remove(newForm);
                                  setState(() {});
                                };
                                lines.add(newForm);
                                setState(() {});
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                            padding: EdgeInsets.all(10.0),
                          )
                        : LongPressDraggable(
                            key: new ObjectKey(index),
                            data: lines[index],
                            child: new DragTarget<NewLineForm>(
                              onAccept: (NewLineForm data) {
                                lines.remove(data);
                                lines.insert(index, data);
                                setState(() {});
                              },
                              onWillAccept: (NewLineForm data) {
                                // Debug
                                return true;
                              },
                              builder: (BuildContext context,
                                  List<NewLineForm> data,
                                  List<dynamic> rejects) {
                                return lines[index];
                              },
                            ),
                            feedback: Card(
                              child: CustomPaint(
                                painter: TabPainter(),
                                child: Container(
                                  height: 50.0,
                                  width: MediaQuery.of(context).size.width,
                                ),
                              ),
                            ),
                            childWhenDragging: Container(
                              height: 20,
                            ),
                          );
                  })),
          Container(
            height: search == null || search == ""
                ? 0
                : MediaQuery.of(context).size.height * 0.5,
            child: StreamBuilder(
                stream: Firestore.instance
                    .collection('users')
                    .where('display_insensitive',
                        isGreaterThanOrEqualTo: search.toUpperCase())
                    .where('display_insensitive',
                        isLessThan: incrementString(search.toUpperCase()))
                    .snapshots(),
                builder: (context, snapshot) {
                  var data = snapshot.data;

                  if (data != null) {
                    users = snapshot.data.documents;
                  }
                  return search == null || search == ""
                      ? Container()
                      : GridView(
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 500.0,
                                  childAspectRatio: 6.0),
                          children: List.generate(users.length, (index) {
                            DocumentSnapshot user = users[index];
                            return FriendTab(
                              friend: User(
                                  displayName: user.data["display"],
                                  imageUrl: user.data["image"],
                                  uid: user.documentID),
                              onPressed: () {
                                lines[editingIndex].uid = user.documentID;
                                lines[editingIndex].name = user.data["display"];
                                reloadLineForm();
                                search = "";
                                setState(() {});
                              },
                            );
                          }));
                }),
          )
        ]));
  }
}

class NewLineForm extends StatefulWidget {
  TextEditingController quoteController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  final ItemScrollController scrollController;
  NewLineForm(
      {this.index,
      this.key,
      this.remove,
      this.scrollController,
      this.searchForName});
  ValueKey key;
  int index;
  String message;
  String name;
  String uid;
  Function remove;
  bool editing = true;
  final Function searchForName;
  Color color = Colors.white;

  @override
  State<StatefulWidget> createState() {
    return NewLineFormState();
  }
}

class NewLineFormState extends State<NewLineForm> {
  @override
  Widget build(BuildContext context) {
    widget.index = lines.indexOf(widget);
    return Stack(children: <Widget>[
      Card(
        color: widget.color,
        child: CustomPaint(
            painter: TabPainter(
                fromLeft: 0.15, height: 36, color: Colors.green[100]),
            child: widget.editing
                ? Column(
                    children: <Widget>[
                      Container(
                        child: Form(
                          child: Column(
                            children: <Widget>[
                              Container(
                                child: RichText(
                                  text: TextSpan(
                                    text: (widget.index + 1).toString(),
                                    style: TextStyle(
                                        fontSize: 17.0,
                                        color: Colors.green[800],
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                margin: EdgeInsets.only(
                                    bottom: 30.0, top: 10.0, left: 20.0),
                                alignment: Alignment.centerLeft,
                              ),
                              Padding(
                                  child: TextFormField(
                                    onTap: () {
                                      editingIndex = widget.index;
                                      widget.scrollController.scrollTo(
                                          index: widget.index,
                                          duration:
                                              Duration(milliseconds: 300));
                                      setState(() {});
                                    },
                                    controller: widget.quoteController,
                                    onChanged: (entry) {
                                      widget.message =
                                          widget.quoteController.text;
                                    },
                                    maxLines: 4,
                                    decoration: InputDecoration(
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 16.0, horizontal: 20),
                                        hintStyle: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20),
                                        hintText: "Quote",
                                        border: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.green, width: 2)),
                                        enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.green,
                                                width: 2))),
                                  ),
                                  padding: EdgeInsets.only(left: 20.0)),
                              Container(
                                height: 20,
                              ),
                              Row(
                                children: <Widget>[
                                  Container(
                                    child: ButtonTheme(
                                      minWidth: 10.0,
                                      child: RaisedButton(
                                        child: Icon(
                                          Icons.check,
                                          color: Colors.white,
                                        ),
                                        color: Colors.green,
                                        elevation: 3.0,
                                        onPressed: () {
                                          if (widget.name == null ||
                                              widget.message == null) {
                                            widget.remove();
                                          }
                                          widget.editing = false;
                                          search = "";
                                          setState(() {});
                                        },
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30.0),
                                        ),
                                      ),
                                    ),
                                    padding:
                                        EdgeInsets.only(right: 5.0, left: 15.0),
                                  ),
                                  Container(
                                    child: ButtonTheme(
                                      minWidth: 10.0,
                                      child: RaisedButton(
                                        child: Icon(
                                          Icons.clear,
                                          color: Colors.white,
                                        ),
                                        color: Colors.red,
                                        elevation: 3.0,
                                        onPressed: () {
                                          widget.remove();
                                          search = "";
                                        },
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30.0),
                                        ),
                                      ),
                                    ),
                                    padding:
                                        EdgeInsets.only(right: 15.0, left: 5.0),
                                  ),
                                  Expanded(
                                      child: widget.uid == null
                                          ? TextFormField(
                                              controller: widget.nameController,
                                              onTap: () {
                                                editingIndex = widget.index;
                                                reloadLineForm = () {
                                                  setState(() {});
                                                };
                                                setState(() {});
                                              },
                                              onChanged: (entry) {
                                                widget.name =
                                                    widget.nameController.text;
                                                search =
                                                    widget.nameController.text;
                                                widget.searchForName();
                                                setState(() {});
                                              },
                                              onEditingComplete: () {
                                                search = "";
                                                widget.searchForName();
                                                setState(() {});
                                              },
                                              decoration: InputDecoration(
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          vertical: 4.0,
                                                          horizontal: 20),
                                                  hintStyle: TextStyle(
                                                      fontWeight: FontWeight
                                                          .bold,
                                                      fontSize: 20),
                                                  hintText: "Name",
                                                  border: OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: Colors.green,
                                                          width: 2)),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
                                                                  color: Colors
                                                                      .green,
                                                                  width: 2))),
                                            )
                                          : Chip(
                                              deleteIcon: Icon(
                                                Icons.cancel,
                                                color: Colors.white,
                                              ),
                                              onDeleted: () {
                                                widget.uid = null;
                                                widget.nameController.text = "";
                                                setState(() {});
                                              },
                                              backgroundColor:
                                                  Colors.green[700],
                                              label: Text(
                                                widget.name,
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            )),
                                ],
                              )
                            ],
                          ),
                        ),
                        padding: EdgeInsets.only(right: 20, bottom: 20.0),
                      ),
                    ],
                  )
                : Column(children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          child: RichText(
                            text: TextSpan(
                              text: (widget.index + 1).toString(),
                              style: TextStyle(
                                  fontSize: 17.0,
                                  color: Colors.green[800],
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          margin: EdgeInsets.only(
                              bottom: 10.0, top: 0.0, left: 20.0),
                          alignment: Alignment.centerLeft,
                        ),
                        Spacer(),
                        FlatButton(
                          padding: EdgeInsets.only(
                              bottom: 10.0, top: 0.0, left: 20.0),
                          child: Container(
                            child: RichText(
                              text: TextSpan(
                                text: "edit",
                                style: TextStyle(
                                    fontSize: 17.0,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            margin: EdgeInsets.only(
                              left: 0.0,
                            ),
                            alignment: Alignment.centerLeft,
                          ),
                          onPressed: () {
                            widget.editing = true;
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    Container(
                      child: Quote(
                          message: widget.message,
                          name: Name(
                            name: widget.name,
                          )),
                      padding: EdgeInsets.only(left: 20.0),
                    )
                  ])),
        elevation: 2,
      ),
    ]);
  }
}

class TagSuggestions extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return null;
  }
}
