import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pearawards/Collections/CollectionStream.dart';
import 'package:pearawards/Home/HomeFeed.dart';
import 'package:pearawards/App/LoginPage.dart';

import 'package:pearawards/Awards/Award.dart';
import 'package:pearawards/Collections/CollectionPage.dart';
import 'package:pearawards/Home/NotificationsPage.dart';
import 'package:pearawards/Notifications/NotificationHandler.dart';
import 'package:pearawards/Search%20Page/SearchPage.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;
import 'package:pearawards/Profile/ProfilePage.dart';
import 'package:pearawards/Utils/Utils.dart';

final Document overripe = Document(
    url:
        "https://docs.google.com/document/d/e/2PACX-1vTSk3SDoGiEVRtYNcylmyGU7hm4ekxdE9x19VFE65In1wV_wDlqI8fNxuSEzZOMz2Nn0KpDu3VAtfv3/pub",
    name: "Overripe");
final Document underripe = Document(
    url:
        "https://docs.google.com/document/d/e/2PACX-1vRj7ehq0PMd6k2fu6UEhHpKOVwEBIRdPui6xkyB8OwcZKMN-dZJg9oBZZuvkXgSQSSQjbRIeTXkUxIE/pub",
    name: "Underripe");

List<Document> documents = [overripe, underripe];

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  bool mostRecent = true;

  TextEditingController searchController = TextEditingController();

  PrimitiveWrapper searchText = PrimitiveWrapper("");
  PrimitiveWrapper searchRefresh = PrimitiveWrapper(false);

  PageController pageController = PageController(initialPage: 0);

  CollectionStream stream;

  int pageIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var pages = <Widget>[
      HomeFeed(),
      SearchPage(searchText: searchText, searchRefresh: searchRefresh),
      CollectionPage(),
      ProfilePage(globals.firebaseUser.uid)
    ];
    List<AppBar> bars = [
      AppBar(
        backgroundColor: Colors.green,
        title: Text("Home"),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.notifications,
            ),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => NotificationsPage()));
            },
          ),
        ],
      ),
      AppBar(
          backgroundColor: Colors.green,
          title: Container(
            height: 35,
            child: TextField(
              onChanged: (content) {
                setState(() {
                  searchText.value = "";
                  searchRefresh.value = true;
                });
                Timer(Duration(milliseconds: 5), () {
                  setState(() {
                    searchText.value = content;
                    searchRefresh.value = true;
                  });
                });
              },
              style: TextStyle(color: Colors.white, fontSize: 20),
              scrollPadding: EdgeInsets.symmetric(vertical: 0.0),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: new BorderRadius.circular(25.0),
                    borderSide: BorderSide(color: Colors.green, width: 2)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: new BorderRadius.circular(25.0),
                    borderSide: BorderSide(color: Colors.green, width: 2)),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0.0, horizontal: 15.0),
                fillColor: Colors.green[300],
                filled: true,
                hintStyle: TextStyle(color: Colors.white, fontSize: 20),
                hintText: "Search",
              ),
              controller: searchController,
            ),
          )),
      AppBar(
        backgroundColor: Colors.green,
        title: Text("Collections"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(100, 100, 0, 0),
                items: <PopupMenuEntry>[
                  PopupMenuItem(
                    child: Container(
                      child: TextField(
                        autocorrect: false,
                        controller: searchController,
                        onChanged: (text) {
                          setState(() {
                            CollectionStream.searchText = text;
                          });
                        },
                      ),
                      width: 250,
                    ),
                  )
                ],
              );
            },
          ),
        ],
      ),
      AppBar(
        backgroundColor: Colors.green,
        title: Text("Profile"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(100, 100, 0, 0),
                items: <PopupMenuEntry>[
                  PopupMenuItem(
                    child: Container(
                      child: TextField(
                        autocorrect: false,
                        controller: searchController,
                        onChanged: (text) {
                          setState(() {
                            CollectionStream.searchText = text;
                          });
                        },
                      ),
                      width: 250,
                    ),
                  )
                ],
              );
            },
          ),
        ],
      ),
    ];
    return Scaffold(
      appBar: bars[pageIndex],
      body: Stack(children: [
        PageView(
          controller: pageController,
          children: pages,
          onPageChanged: (newPage) {
            pageIndex = newPage;
            setState(() {});
          },
        ),
        NotificationHandler()
      ]),
      drawer: buildDrawer(),
      bottomNavigationBar: BottomNavigationBar(
        unselectedItemColor: Colors.grey[600],
        selectedItemColor: Colors.green[600],
        onTap: (index) {
          setState(() {
            pageIndex = index;
            pageController.jumpToPage(index);
          });
        },
        currentIndex: pageIndex,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), title: Text("Home")),
          BottomNavigationBarItem(
              icon: Icon(Icons.search), title: Text("Search")),
          BottomNavigationBarItem(
              icon: Icon(Icons.collections_bookmark),
              title: Text("Collections")),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), title: Text("Profile")),
        ],
      ),
    );
  }

  Drawer buildDrawer() {
    return Drawer(
      child: Column(
        children: <Widget>[
          AppBar(
            backgroundColor: Colors.green,
            title: Text("Options"),
          ),
          Container(
            child: Row(
              children: <Widget>[
                Text("Order: "),
                Expanded(
                  child: ChoiceChip(
                    labelStyle: TextStyle(
                        color: mostRecent ? Colors.green : Colors.black87),
                    label: Text('Latest'),
                    onSelected: (bool selected) {
                      setState(() {
                        mostRecent = selected;
                      });
                    },
                    selected: mostRecent,
                  ),
                ),
                Expanded(
                  child: ChoiceChip(
                    label: Text('First'),
                    onSelected: (bool selected) {
                      setState(() {
                        mostRecent = !selected;
                      });
                    },
                    selected: !mostRecent,
                  ),
                ),
              ],
            ),
            margin: EdgeInsets.all(10.0),
          ),
          /*Container(
            height: MediaQuery.of(context).size.height * 0.7,
            child: ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  key: ObjectKey(documents[index]),
                  child: RaisedButton(
                    child: Text(documents[index].name),
                    onPressed: () {
                      pageIndex = index;
                      setState(() {
                        stream = CollectionStream(
                          url: documents[index].url,
                          title: documents[index].name,
                        );
                        Navigator.of(context).pop();
                      });
                    },
                  ),
                  onDismissed: (direction) {
                    Document temp = documents[index];
                    documents.removeAt(index);
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Document deleted'),
                            actions: <Widget>[
                              new FlatButton(
                                child: new Text('UNDO'),
                                onPressed: () {
                                  documents.insert(index, temp);
                                  Navigator.of(context).pop();
                                },
                              ),
                              new FlatButton(
                                child: new Text('OK'),
                                onPressed: () {
                                  setState(() {});
                                  Navigator.of(context).pop();
                                },
                              )
                            ],
                          );
                        });
                  },
                );
              },
            ),
          ),*/
          RaisedButton(
            child: Text("Log Out"),
            onPressed: () {
              //TODO: DELETE DEVICE ID
              globals.firebaseAuth.signOut();
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) => LoginPage(),
              ));
            },
          ),
          Spacer(),
          RaisedButton(
            child: Text("Attributions"),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      Scaffold(
                    appBar: AppBar(
                      title: Text("Attributions"),
                    ),
                    body: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 20.0),
                      child: Column(
                        children: <Widget>[
                          //Text("Comments icon created by Alice Design from Noun Project")
                        ],
                      ),
                    ),
                  ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return ScaleTransition(
                        scale: animation.drive(CurveTween(curve: Curves.ease)),
                        alignment: Alignment.center,
                        child: child);
                  },
                ),
              );
            },
          ),
          Container(
            height: 100,
          )
        ],
      ),
    );
  }
}
