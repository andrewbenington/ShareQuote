import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Upload.dart';
import 'Award.dart';
import 'CustomPainters.dart';
import 'Globals.dart' as globals;

List<NewLineForm> lines = [];

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

  @override
  void initState() {
    lines = [];
    super.initState();
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
                        ),
                      ));
                    }
                  }
                  if (quotes.length > 0) {
                    uploadNewAward(
                        globals.firebaseUser,
                        Award(
                            quotes: quotes,
                            timestamp: DateTime.now().microsecondsSinceEpoch,
                            author: Name(
                              uid: globals.firebaseUser.uid,
                              name: globals.firebaseUser.displayName,
                            )),
                        widget.title);
                    Navigator.pop(context, true);
                  } else {
                    Navigator.pop(context, false);
                  }
                }),
          ],
          leading: IconButton(
            icon: Icon(Icons.close, size: 30),
            onPressed: () {
              Navigator.pop(context, false);
            },
          ),
          title: Text("Add Award"),
        ),
        backgroundColor: Colors.green[200],
        body: Column(children: <Widget>[
          Expanded(
              child: ListView.builder(
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
                                  remove: () {
                                    lines.remove(this);
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
        ]));
  }
}

class NewLineForm extends StatefulWidget {
  TextEditingController quoteController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController url_controller = TextEditingController();
  NewLineForm({this.index, this.key, this.remove});
  ValueKey key;
  int index;
  String message;
  String name;
  Function remove;
  bool editing = true;
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
            painter: TabPainter(),
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
                                        onPressed: widget.remove,
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
                                    child: TextFormField(
                                      controller: widget.nameController,
                                      onChanged: (entry) {
                                        widget.name =
                                            widget.nameController.text;
                                      },
                                      decoration: InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 4.0, horizontal: 20),
                                          hintStyle: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20),
                                          hintText: "Name",
                                          border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.green,
                                                  width: 2)),
                                          enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.green,
                                                  width: 2))),
                                    ),
                                  ),
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
                      margin:
                          EdgeInsets.only(bottom: 30.0, top: 10.0, left: 20.0),
                      alignment: Alignment.centerLeft,
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
