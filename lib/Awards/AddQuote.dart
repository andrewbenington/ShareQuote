import 'dart:async';
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
Function reloadPage;

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
  GridView userTiles;
  Map following;

  @override
  void initState() {
    search = "";
    var newForm = NewLineForm(
      index: lines.length,
      scrollController: scrollController,
      searchForName: () {
        loadUsers();
        setState(() {});
      },
    );
    newForm.remove = () {
      lines.remove(newForm);
      setState(() {});
    };
    lines.add(newForm);
    super.initState();
    lines = [newForm];
  }

  loadUsers() async {
    if (search == null || search == "") {
      users = [];
    } else {
      users = await Firestore.instance
          .collection('users')
          .where('display_insensitive',
              isGreaterThanOrEqualTo: search.toUpperCase())
          .where('display_insensitive',
              isLessThan: incrementString(search.toUpperCase()))
          .limit(50)
          .getDocuments()
          .then((docs) {
        return docs.documents;
      });
    }
    userTiles = GridView(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 500.0, childAspectRatio: 6.0));
    setState(() {});
    Timer(Duration(milliseconds: 10), () {
      userTiles = GridView(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 500.0, childAspectRatio: 6.0),
        children: List.generate(users.length, (index) {
          DocumentSnapshot user = users[index];
          return UserTab(
            user: User(
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
        }),
      );
      setState(() {});
    });
  }

  loadFollowing() async {
    var me = await Firestore.instance.document('users/${globals.me.uid}').get();
    following = me.data['following'];
    if (following == null) {
      following = Map();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    reloadPage = () {
      setState(() {});
    };
    return Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.check, size: 30),
                onPressed: () {
                  List<Quote> quotes = [];
                  Map people = {};
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
                    if (form.uid == null) {
                      people[form.name.trim()] = {
                        "name": form.name,
                        "uid": form.uid
                      };
                    } else {
                      people[form.uid] = {"name": form.name, "uid": form.uid};
                    }
                  }
                  if (quotes.length > 0) {
                    Award a = Award(
                        people: people.values.toList(),
                        quotes: quotes,
                        timestamp: DateTime.now().microsecondsSinceEpoch,
                        author: Name(
                          uid: globals.me.uid,
                          name: globals.me.displayName,
                        ));
                    uploadNewAward('users/${globals.me.uid}/created_awards', a,
                        widget.document, true);
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
        backgroundColor: globals.theme.backgroundColor,
        body: Column(children: <Widget>[
          Expanded(
              child: ScrollablePositionedList.builder(
                  physics: ClampingScrollPhysics(),
                  itemScrollController: scrollController,
                  itemCount: lines.length + 1,
                  itemBuilder: (context, index) {
                    return index == lines.length
                        ? Row(children: [
                            Expanded(
                              child: Padding(
                                child: RaisedButton(
                                  child: Text(
                                    "Add Quote",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white),
                                  ),
                                  color: globals.theme.primaryColor,
                                  elevation: 3.0,
                                  onPressed: () {
                                    var newForm = NewLineForm(
                                      index: lines.length,
                                      scrollController: scrollController,
                                      searchForName: () {
                                        loadUsers();
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
                              ),
                            ),
                            Padding(
                              child: RaisedButton(
                                child: Text(
                                  "Add Action",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white),
                                ),
                                color: Colors.grey[600],
                                elevation: 3.0,
                                onPressed: () {
                                  var newForm = NewLineForm(
                                    index: lines.length,
                                    action: true,
                                    scrollController: scrollController,
                                    searchForName: () {
                                      loadUsers();
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
                          ])
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
          search == null || search == ""
              ? Container()
              : Expanded(
                  /*height: MediaQuery.of(context).size.height * 0.5,*/
                  child: userTiles == null || search == null || search == ""
                      ? Container()
                      : userTiles)
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
      this.searchForName,
      this.action = false});
  ValueKey key;
  int index;
  String message;
  String name;
  String uid;
  bool action;
  Function remove;
  bool editing = true;
  final Function searchForName;
  Color color = globals.theme.backgroundColor;

  @override
  State<StatefulWidget> createState() {
    return NewLineFormState();
  }
}

class NewLineFormState extends State<NewLineForm> {
  @override
  Widget build(BuildContext context) {
    bool quoteMissing = false;
    bool nameMissing = false;
    widget.index = lines.indexOf(widget);
    return Stack(children: <Widget>[
      Card(
        color: globals.theme.cardColor,
        child: CustomPaint(
            painter: TabPainter(
                fromLeft: 0.15,
                height: 36,
                color:
                    widget.action ? Colors.grey : globals.theme.lightPrimary),
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
                                        color: globals.theme.textColor,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                margin: EdgeInsets.only(
                                    bottom: 30.0, top: 10.0, left: 20.0),
                                alignment: Alignment.centerLeft,
                              ),
                              Padding(
                                  child: TextFormField(
                                    style: TextStyle(
                                        color: widget.action
                                            ? Colors.grey
                                            : globals.theme.textColor),
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
                                            fontWeight: FontWeight.w600,
                                            fontSize: 20,
                                            fontStyle: widget.action
                                                ? FontStyle.italic
                                                : FontStyle.normal,
                                            color: Colors.grey[600]),
                                        hintText: widget.action
                                            ? "*Action*"
                                            : "\"Quote\"",
                                        border: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: widget.action
                                                    ? Colors.grey
                                                    : globals
                                                        .theme.primaryColor,
                                                width: 2)),
                                        enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: widget.action
                                                    ? Colors.grey
                                                    : globals
                                                        .theme.primaryColor,
                                                width: 2)),
                                        focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: widget.action
                                                    ? Colors.grey
                                                    : globals.theme.textColor,
                                                width: 2))),
                                  ),
                                  padding: EdgeInsets.only(left: 20.0)),
                              Container(
                                height: 20,
                              ),
                              Row(
                                children: <Widget>[
                                  widget.action ? Spacer() : Container(),
                                  Container(
                                    child: ButtonTheme(
                                      minWidth: 10.0,
                                      child: RaisedButton(
                                        child: Icon(
                                          Icons.check,
                                          color: Colors.white,
                                        ),
                                        color: globals.theme.primaryColor,
                                        elevation: 3.0,
                                        onPressed: () {
                                          if (widget.message == null) {
                                            quoteMissing = true;
                                          } else {
                                            quoteMissing = false;
                                          }
                                          if (!widget.action &&
                                              widget.name == null) {
                                            nameMissing = true;
                                          } else {
                                            nameMissing = false;
                                          }
                                          if (!quoteMissing && !nameMissing) {
                                            widget.editing = false;
                                            search = "";
                                            setState(() {});
                                          }
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
                                          color: globals.theme.primaryColor,
                                        ),
                                        color: Colors.white,
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
                                  widget.action ? Spacer() : Container(),
                                  widget.action
                                      ? Container()
                                      : Expanded(
                                          child: widget.uid == null
                                              ? TextFormField(
                                                  style: TextStyle(
                                                      color: globals
                                                          .theme.textColor),
                                                  controller:
                                                      widget.nameController,
                                                  onTap: () {
                                                    editingIndex = widget.index;
                                                    reloadLineForm = () {
                                                      setState(() {});
                                                    };
                                                    setState(() {});
                                                  },
                                                  onChanged: (entry) {
                                                    widget.name = widget
                                                        .nameController.text;
                                                    search = widget
                                                        .nameController.text;
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
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 20,
                                                          color:
                                                              Colors.grey[600]),
                                                      hintText: "- Name",
                                                      border: OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                              color: globals
                                                                  .theme
                                                                  .primaryColor,
                                                              width: 2)),
                                                      enabledBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                              color: globals
                                                                  .theme
                                                                  .primaryColor,
                                                              width: 2)),
                                                      focusedBorder:
                                                          OutlineInputBorder(
                                                              borderSide: BorderSide(color: globals.theme.textColor, width: 2))),
                                                )
                                              : Chip(
                                                  deleteIcon: Icon(
                                                    Icons.cancel,
                                                    color: globals
                                                        .theme.backgroundColor,
                                                  ),
                                                  onDeleted: () {
                                                    widget.uid = null;
                                                    widget.nameController.text =
                                                        "";
                                                    setState(() {});
                                                  },
                                                  backgroundColor: globals
                                                      .theme.lightPrimary,
                                                  label: Text(
                                                    widget.name,
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w600),
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
                                  color: widget.action
                                      ? Colors.grey[600]
                                      : globals.theme.darkPrimary,
                                  fontWeight: FontWeight.w600),
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
                                    color: widget.action ? Colors.white : globals.theme.backTextColor,
                                    fontWeight: FontWeight.w600),
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
                    widget.action
                        ? Container(
                            child: Context(
                              message: widget.message,
                            ),
                            padding: EdgeInsets.only(left: 20.0),
                          )
                        : Container(
                            child: Quote(
                                message: widget.message,
                                name: Name(
                                  name: widget.name,
                                )),
                            padding: EdgeInsets.only(left: 20.0),
                          ),
                    Row(
                      children: <Widget>[
                        Container(
                          child: ButtonTheme(
                            minWidth: 10.0,
                            child: RaisedButton(
                              child: Icon(
                                Icons.arrow_upward,
                                color: Colors.white,
                              ),
                              color: globals.theme.primaryColor,
                              elevation: 3.0,
                              onPressed: () {
                                if (0 == widget.index) {
                                  return;
                                }
                                var temp = lines[widget.index - 1];
                                temp.index += 1;
                                lines[widget.index - 1] = lines[widget.index];
                                lines[widget.index] = temp;
                                setState(() {
                                  widget.index -= 1;
                                  reloadPage();
                                });
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                          ),
                          padding: EdgeInsets.only(
                              right: 5.0, left: 15.0, bottom: 15.0),
                        ),
                        Container(
                          child: ButtonTheme(
                            minWidth: 10.0,
                            child: RaisedButton(
                              child: Icon(
                                Icons.arrow_downward,
                                color: Colors.white,
                              ),
                              color: globals.theme.primaryColor,
                              elevation: 3.0,
                              onPressed: () {
                                if (lines.length - 1 <= widget.index) {
                                  return;
                                }
                                var temp = lines[widget.index + 1];
                                temp.index -= 1;
                                lines[widget.index + 1] = lines[widget.index];
                                lines[widget.index] = temp;
                                setState(() {
                                  widget.index += 1;
                                  reloadPage();
                                });
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                          ),
                          padding: EdgeInsets.only(
                              right: 15.0, left: 5.0, bottom: 15.0),
                        )
                      ],
                    )
                  ])),
        elevation: 2,
      ),
    ]);
  }
}
