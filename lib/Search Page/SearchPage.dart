import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Awards/AwardsStream.dart';
import 'package:pearawards/Profile/User.dart';
import 'package:pearawards/Utils/DisplayTools.dart';
import 'package:pearawards/Utils/Utils.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;

class SearchPage extends StatefulWidget {
  SearchPage({this.searchText, this.searchRefresh});
  final PrimitiveWrapper searchText;
  final PrimitiveWrapper searchRefresh;

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
  TextEditingController searchController = TextEditingController();
  StreamBuilder<QuerySnapshot> stream;

  @override
  void initState() {
    super.initState();
  }

  Future<void> refreshAll() async {
    return;
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
    if (widget.searchText.value == null || widget.searchText.value == "") {
      stream = null;
    } else {
      stream = userStream(widget.searchText.value);
    }
    tabPages = [
      stream == null
          ? SliverToBoxAdapter(child: Container())
          : RefreshIndicator(
              onRefresh: () {
                return refreshAll();
              },
              child: stream,
            ),
      AwardsStream(
        docRef:
            Firestore.instance.document('users/${globals.firebaseUser.uid}'),
        directoryName: 'feed',
        shouldLoad: shouldLoad,
        refreshParent: () {
          setState(() {});
        },
        isLoading: isLoading,
        noAwards: noAwards,
        filter: filter,
        searchText: widget.searchText,
      ),
    ];
    return Scaffold(
        backgroundColor: Colors.green[200],
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
                      indicatorColor: Colors.white,
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
