import 'package:flutter/material.dart';
import 'package:pearawards/HomeFeed.dart';
import 'package:pearawards/LoginPage.dart';

import 'Award.dart';
import 'AwardsStream.dart';
import 'CollectionPage.dart';
import 'Globals.dart' as globals;
import 'ProfilePage.dart';

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

  TextEditingController name_controller = TextEditingController();
  TextEditingController url_controller = TextEditingController();
  TextEditingController search_controller = TextEditingController();

  PageController pageController = PageController();

  AwardsStream stream;

  int pageIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var pages = <Widget>[CollectionPage(), HomeFeed(), ProfilePage()];
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Colors.green,
      //   title: Text("Home"),
      //   actions: <Widget>[
      //     IconButton(
      //       icon: Icon(Icons.search),
      //       onPressed: () {
      //         showMenu(
      //           context: context,
      //           position: RelativeRect.fromLTRB(100, 100, 0, 0),
      //           items: <PopupMenuEntry>[
      //             PopupMenuItem(
      //               child: Container(
      //                 child: TextField(
      //                   autocorrect: false,
      //                   controller: search_controller,
      //                   onChanged: (text) {
      //                     setState(() {
      //                       AwardsStream.searchText = text;
      //                     });
      //                   },
      //                 ),
      //                 width: 250,
      //               ),
      //             )
      //           ],
      //         );
      //       },
      //     ),
      //   ],
      // ),
      body: PageView(
        controller: pageController,
        children: pages,
        onPageChanged: (newPage) {
          pageIndex = newPage;
          setState(() {});
        },
      ),
      drawer: buildDrawer(),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          setState(() {
            pageIndex = index;
            pageController.jumpToPage(index);
          });
        },
        currentIndex: pageIndex,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.collections_bookmark),
              title: Text("Collections")),
          BottomNavigationBarItem(icon: Icon(Icons.home), title: Text("Home")),
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
                        stream = AwardsStream(
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
              globals.firebaseAuth.signOut();
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) => LoginPage(),
              ));
            },
          ),
        ],
      ),
    );
  }
}
