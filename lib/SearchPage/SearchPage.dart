import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Awards/AwardsStream.dart';
import 'package:pearawards/Collections/CollectionPage.dart';
import 'package:pearawards/Profile/User.dart';
import 'package:pearawards/Utils/DisplayTools.dart';
import 'package:pearawards/Utils/Utils.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;

class SearchPage extends StatefulWidget {
  SearchPage({this.searchText, this.searchRefresh, this.searchController});
  final PrimitiveWrapper searchText;
  final PrimitiveWrapper searchRefresh;
  final TextEditingController searchController;

  @override
  State<StatefulWidget> createState() {
    return _SearchPageState();
  }
}

class _SearchPageState extends State<SearchPage> {
  PrimitiveWrapper shouldLoad = PrimitiveWrapper(false);
  PrimitiveWrapper isLoading = PrimitiveWrapper(false);
  PrimitiveWrapper filter = PrimitiveWrapper(false);

  final PrimitiveWrapper noAwards = PrimitiveWrapper(false);
  Key tabKey = Key('tabbar');
  int tabIndex = 0;
  List tabPages = [];
  bool loading = false;
  List following = [];
  List users;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(() {
      if (mounted) {
        loadUsers();
      }
    });
  }

  Future<void> refreshAll() async {
    return;
  }

  loadUsers() async {
    if (widget.searchController.text == null ||
        widget.searchController.text == "") {
      users = [];
    } else {
      users = [];
      setState(() {});
      Timer(Duration(milliseconds: 10), () async {
        users = await Firestore.instance
            .collection('users')
            .where('display_insensitive',
                isGreaterThanOrEqualTo:
                    widget.searchController.text.toUpperCase())
            .where('display_insensitive',
                isLessThan:
                    incrementString(widget.searchController.text.toUpperCase()))
            .limit(50)
            .getDocuments()
            .then((docs) {
          return docs.documents;
        });
        setState(() {});
      });
    }
  }

  Future<void> loadData() async {
    DocumentSnapshot me = await Firestore.instance
        .document('users/${globals.firebaseUser.uid}')
        .get();

    if (me.data["following"] != null) {
      following = me.data["following"].keys.toList();
    } else {
      following = [];
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    tabPages = [
      users == null || users.length == 0
          ? SliverToBoxAdapter(child: Container())
          : RefreshIndicator(
              onRefresh: () {
                return refreshAll();
              },
              child: widget.searchController.text == null ||
                      widget.searchController.text == ""
                  ? SliverList(
                      delegate: SliverChildListDelegate([Container()]),
                    )
                  : SliverGrid(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 500.0, childAspectRatio: 6.0),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        DocumentSnapshot user = users[index];
                        return UserTab(
                          user: User(
                              displayName: user.data["display"],
                              imageUrl: user.data["image"],
                              uid: user.documentID),
                          onPressed: () {
                            visitUserPage(user.documentID, context);
                          },
                        );
                      }, childCount: users.length))),
      widget.searchController.text == null || widget.searchController.text == ""
          ? SliverList(
              delegate: SliverChildListDelegate([Container()]),
            )
          : AwardsStream(
              docRef: Firestore.instance
                  .document('users_private/${globals.firebaseUser.uid}'),
              directoryName: 'feed',
              shouldLoad: shouldLoad,
              refreshParent: () {
                setState(() {});
              },
              isLoading: isLoading,
              noAwards: noAwards,
              filter: filter,
              searchText: widget.searchText,
              mostRecent: PrimitiveWrapper(true),
            ),
    ];
    return Scaffold(
        backgroundColor: globals.theme.backgroundColor,
        body: Stack(children: [
          DefaultTabController(
            key: tabKey,
            length: tabPages.length,
            child: CustomScrollView(
              slivers: <Widget>[
                SliverPersistentHeader(
                  floating: true,
                  delegate: SliverTabBarDelegate(
                    TabBar(
                      indicatorColor: globals.theme.backgroundColor,
                      labelPadding: EdgeInsets.symmetric(vertical: 10.0),
                      onTap: (index) {
                        shouldLoad.value = true;
                        rebuildAllChildren(context);
                        setState(() {
                          tabIndex = index;
                        });
                      },
                      tabs: [
                        Tab(text: 'People'),
                        Tab(child: Text('Awards')),
                        //Tab(icon: Icon(Icons.people), text: 'Friends'),
                      ],
                    ),
                  ),
                ),
                tabPages[tabIndex]
              ],
            ),
          ),
          !loading
              ? Container()
              : Center(
                  child: CircularProgressIndicator(),
                )
        ]));
  }
}
