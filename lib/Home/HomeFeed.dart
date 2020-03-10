import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pearawards/Awards/AddQuote.dart';
import 'package:pearawards/Awards/Award.dart';
import 'package:pearawards/Awards/AwardsStream.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Utils/Converter.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;
import 'package:pearawards/Utils/Utils.dart';

class HomeFeed extends StatefulWidget {
  static String searchText;

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  _HomeFeedState createState() => _HomeFeedState();

  void setSearchText(String search) {
    searchText = search;
    createState();
  }

  String getTitle() {
    return awardTitle;
  }
}

class _HomeFeedState extends State<HomeFeed> {
  bool mostRecent = true;
  String errorMessage = "";
  PrimitiveWrapper shouldLoad = PrimitiveWrapper(false);
  PrimitiveWrapper isLoading = PrimitiveWrapper(false);
  PrimitiveWrapper filter = PrimitiveWrapper(false);
  final PrimitiveWrapper noAwards = PrimitiveWrapper(false);

  @override
  void initState() {
    super.initState();
    shouldLoad.value = true;
  }

  Future<void> refresh() async {
    shouldLoad.value = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: globals.theme.backgroundColor,
      body: Stack(children: <Widget>[
        Center(
          child: RefreshIndicator(
            child: CustomScrollView(slivers: <Widget>[
                    SliverList(
                      delegate: SliverChildListDelegate([Container()]),
                    ),
                    AwardsStream(
                      docRef: Firestore.instance.document(
                          'users_private/${globals.me.uid}'),
                      directoryName: 'feed',
                      shouldLoad: shouldLoad,
                      refreshParent: () {
                        if (mounted) {
                          refresh();
                        }
                      },
                      isLoading: isLoading,
                      noAwards: noAwards,
                      filter: filter,
                    ),
                  ]),
            onRefresh: refresh,
          ),
        ),
        Container(
          child: isLoading.value
              ? Center(child: CircularProgressIndicator())
              : null,
          constraints: BoxConstraints.expand(),
        )
      ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: globals.theme.primaryColor,
        onPressed: () {
          newAward();
        },
        tooltip: 'New Award',
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  newAward() async {
    Award another = await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => AddQuote(
            document: null,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
                scale: animation.drive(CurveTween(curve: Curves.ease)),
                alignment: Alignment.center,
                child: child);
          },
        ));
    if (another != null) {
      shouldLoad.value = true;
    }
  }
}
