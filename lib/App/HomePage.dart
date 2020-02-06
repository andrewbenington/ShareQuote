import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Collections/CollectionStream.dart';
import 'package:pearawards/Home/HomeFeed.dart';
import 'package:pearawards/App/LoginPage.dart';
import 'package:pearawards/Awards/Award.dart';
import 'package:pearawards/Collections/CollectionPage.dart';
import 'package:pearawards/Home/NotificationsPage.dart';
import 'package:pearawards/Notifications/NotificationHandler.dart';
import 'package:pearawards/SearchPage/SearchPage.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;
import 'package:pearawards/Profile/ProfilePage.dart';
import 'package:pearawards/Utils/Utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    globals.pages = <Widget>[
      HomeFeed(),
      SearchPage(
        searchText: searchText,
        searchRefresh: searchRefresh,
        searchController: searchController,
      ),
      CollectionPage(),
      ProfilePage(globals.firebaseUser.uid)
    ];
    List<AppBar> bars = [
      AppBar(
        backgroundColor: globals.theme.primaryColor,
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
          backgroundColor: globals.theme.primaryColor,
          title: Container(
            height: 35,
            child: TextField(
              onChanged: (content) {
                searchText.value = content;
                searchRefresh.value = true;
                setState(() {});
              },
              style: TextStyle(color: globals.theme.textColor, fontSize: 20),
              scrollPadding: EdgeInsets.symmetric(vertical: 0.0),
              cursorColor: globals.theme.backgroundColor,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: new BorderRadius.circular(25.0),
                    borderSide: BorderSide(
                        color: globals.theme.primaryColor, width: 2)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: new BorderRadius.circular(25.0),
                    borderSide: BorderSide(
                        color: globals.theme.primaryColor, width: 2)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: new BorderRadius.circular(25.0),
                    borderSide:
                        BorderSide(color: globals.theme.darkPrimary, width: 2)),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0.0, horizontal: 15.0),
                fillColor: globals.theme.lightPrimary,
                filled: true,
                hintStyle: TextStyle(color: Colors.white, fontSize: 20),
                hintText: "Search",
              ),
              controller: searchController,
            ),
          )),
      AppBar(
        backgroundColor: globals.theme.primaryColor,
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
        backgroundColor: globals.theme.primaryColor,
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
            children: globals.pages,
            onPageChanged: (newPage) {
              pageIndex = newPage;
              setState(() {});
            },
          ),
          NotificationHandler()
        ]),
        drawer: buildDrawer(),
        bottomNavigationBar: Material(
          color: globals.theme.primaryColor,
          child: Theme(
            data: Theme.of(context).copyWith(
                textTheme:
                    TextTheme(caption: TextStyle(color: Colors.black45))),
            child: BottomNavigationBar(
              unselectedItemColor: Colors.grey[600],
              selectedItemColor: globals.theme.primaryColor,
              onTap: (index) {
                setState(() {
                  pageIndex = index;
                  pageController.jumpToPage(index);
                });
              },
              currentIndex: pageIndex,
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                    icon: Icon(Icons.home), title: Text("Home")),
                BottomNavigationBarItem(
                    icon: Icon(Icons.search), title: Text("Search")),
                BottomNavigationBarItem(
                    icon: Icon(Icons.collections_bookmark),
                    title: Text("Collections")),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person), title: Text("Profile")),
              ],
            ),
          ),
        ));
  }

  Drawer buildDrawer() {
    return Drawer(
      child: Column(
        children: <Widget>[
          AppBar(
            backgroundColor: globals.theme.primaryColor,
            title: Text("Options"),
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

          Expanded(
            child: Padding(
                child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 15,
                    children: <Widget>[Text("Theme: ")] +
                        List.generate(globals.themes.length, ((index) {
                          return ChoiceChip(
                            selectedColor: globals.theme.primaryColor,
                            labelStyle: TextStyle(
                                color: globals.theme ==
                                        globals.themes.values.elementAt(index)
                                    ? Colors.white
                                    : Colors.black87),
                            label: Text(globals.themes.keys.elementAt(index)),
                            onSelected: (bool selected) {
                              storeTheme(globals.themes.keys.elementAt(index));
                              globals.changeTheme(
                                  globals.themes.keys.elementAt(index));
                              setState(() {});
                              rebuildAllChildren(context);
                            },
                            selected: globals.theme ==
                                globals.themes.values.elementAt(index),
                          );
                        }))), padding: EdgeInsets.symmetric(vertical: 15),),
          ),
          RaisedButton(
            child: Text(
              "Log Out",
              style: TextStyle(color: Colors.white),
            ),
            color: globals.theme.primaryColor,
            onPressed: () {
              //TODO: DELETE DEVICE ID
              globals.firebaseAuth.signOut();
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) => LoginPage(),
              ));
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

storeTheme(String theme) async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  preferences.setString("theme", theme);
}
