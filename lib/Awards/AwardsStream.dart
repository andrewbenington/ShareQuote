import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:pearawards/Utils/Converter.dart';
import 'package:pearawards/Utils/Upload.dart';
import 'package:pearawards/Utils/Utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;

import 'Award.dart';
import 'package:pearawards/Collections/Collection.dart';

int currentIndex = 0;

class AwardsStream extends StatefulWidget {
  static String searchText;
  AwardsStream(
      {Key key,
      this.docRef,
      this.directReferences = false,
      this.collectionInfo,
      this.title,
      this.shouldLoad,
      this.refreshParent,
      this.directoryName = "awards",
      this.isLoading,
      this.noAwards,
      this.numAwards})
      : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
  final bool directReferences;
  final Collection collectionInfo;
  final DocumentReference docRef;
  final String directoryName;
  final PrimitiveWrapper shouldLoad;
  final PrimitiveWrapper isLoading;
  final PrimitiveWrapper noAwards;
  final Function refreshParent;
  final PrimitiveWrapper numAwards;
  String title;

  @override
  _AwardsStreamState createState() => _AwardsStreamState();

  String getTitle() {
    return title;
  }
}

class _AwardsStreamState extends State<AwardsStream> {
  TextEditingController urlController = TextEditingController();
  bool error = false;
  bool mostRecent = true;
  Drawer drawer;
  List<AwardLoader> awards;
  bool updated = false;
  PrimitiveWrapper loaded = PrimitiveWrapper(0);
  Map lastEdits;
  bool populateMap = false;
  bool auditing = false;

  String errorMessage = "";
  @override
  void initState() {
    super.initState();

    awards = [];
    if (widget.collectionInfo == null) {
      refresh();
    } else if (widget.collectionInfo.loaded) {
      awards = List.generate(widget.collectionInfo.awards.length, (a) {
        return AwardLoader(
            award: widget.collectionInfo.awards[a],
            refresh: widget.refreshParent);
      });
      refresh();
    } else {
      attemptLoadAwards();
    }
  }

  attemptLoadAwards() async {
    widget.shouldLoad.value = true;
    final prefs = (await SharedPreferences.getInstance());
    String jsonString =
        prefs.getString(widget.collectionInfo.docRef.documentID);

    if (jsonString != null) {
      print("stored");
      Map json = jsonDecode(jsonString);
      List<Award> loadedAwards = [];
      for (Map m in json["awards"]) {
        loadedAwards.add(Award.fromJson(m));
      }
      widget.collectionInfo.awards = loadedAwards;
      widget.collectionInfo.loaded = true;
      widget.collectionInfo.lastLoaded = json["lastLoaded"];
    }
    refresh();
  }

  refresh() async {
    auditing = false;
    if (!widget.isLoading.value) {
      await loadAwards();
      if (widget.collectionInfo != null && await auditDocument()) {
        loadAwards();
      }
    }
  }

  loadAwards() async {
    widget.isLoading.value = true;
    DocumentSnapshot dSnapshot = await widget.docRef.get();
    if (!dSnapshot.exists) {
      Navigator.pop(context, true);
      widget.isLoading.value = false;
      return;
    }
    lastEdits = dSnapshot.data["awardEdits"];

    if (lastEdits == null) {
      populateMap = true;
      lastEdits = Map();
    }

    if (widget.directReferences) {
      QuerySnapshot docs =
          await widget.docRef.collection(widget.directoryName).getDocuments();
      awards = List.generate(docs.documents.length, (index) {
        return AwardLoader(
            snap: docs.documents[index], refresh: widget.refreshParent);
      });
      if (widget.numAwards != null) {
        widget.numAwards.value = awards.length;
      }
      widget.isLoading.value = false;
      widget.shouldLoad.value = false;
      if (mounted) {
        setState(() {});
      }
      return;
    }

    if (widget.collectionInfo != null) {
      int server = dSnapshot.data["lastEdit"];
      if (server != null && widget.collectionInfo.lastLoaded > server) {
        if (awards == null || awards.length == 0) {
          awards = List.generate(widget.collectionInfo.awards.length, (a) {
            return AwardLoader(
                award: widget.collectionInfo.awards[a],
                refresh: widget.refreshParent);
          });
        }
        awards.sort((a, b) {
          return b.award.timestamp - a.award.timestamp;
        });
        if (widget.numAwards != null) {
          widget.numAwards.value = awards.length;
        }
        if (awards.length > 0) {
          widget.noAwards.value = false;
        }
        widget.isLoading.value = false;
        widget.shouldLoad.value = false;
        setState(() {});
        widget.refreshParent();

        return;
      } else {
        print("reloaded all awards");
      }
    }
    loaded.value = 0;
    awards = [];
    QuerySnapshot snapshot =
        await widget.docRef.collection(widget.directoryName).getDocuments();
    if (snapshot.documents.length == 0) {
      widget.noAwards.value = true;
      widget.isLoading.value = false;
      widget.shouldLoad.value = false;
      if (widget.refreshParent != null) {
        widget.refreshParent();
      }
      if (mounted) {
        setState(() {});
      }
    }
    if (widget.numAwards != null) {
      widget.numAwards.value = snapshot.documents.length;
    }

    for (DocumentSnapshot doc in snapshot.documents) {
      AwardLoader loader = AwardLoader(
          pointer: doc.reference,
          reference: doc.data["reference"],
          numLoaded: loaded,
          lastEdit:
              lastEdits[doc.documentID] == null ? 0 : lastEdits[doc.documentID],
          refresh: widget.refreshParent);
      initAward(loader);
    }
  }

  initAward(AwardLoader loader) async {
    if (mounted) {
      setState(() {});
    }

    await loader.loadAward();
    awards.add(loader);

    if (loaded.value != awards.length) {
      print("${loaded.value} is not ${awards.length}!");
    }
    if (widget.collectionInfo != null && loaded.value >= awards.length) {
      awards.sort((a, b) {
        return b.award.timestamp - a.award.timestamp;
      });
      storeAwards();
    }
    if (loaded.value >= awards.length) {
      widget.isLoading.value = false;
      widget.shouldLoad.value = false;
      if (awards.length > 0) {
        widget.noAwards.value = false;
      }
      if (lastEdits.length == 0 && awards.length > 0) {
        initEdits();
      }
      if (widget.refreshParent != null) {
        widget.refreshParent();
      }
      if (mounted) {
        setState(() {});
      }
    }
  }

  initEdits() async {
    int lastEdit = (await widget.collectionInfo.docRef.get()).data["lastEdit"];
    if (lastEdit == null) {
      await widget.collectionInfo.docRef.setData(
          {"lastEdit": DateTime.now().microsecondsSinceEpoch},
          merge: true);
    }
    lastEdits = Map.fromIterable(awards,
        key: (a) => a.award.hash.toString(), value: (a) => lastEdit);
    widget.collectionInfo.docRef
        .setData({"awardEdits": lastEdits}, merge: true);
  }

  storeAwards() async {
    widget.collectionInfo.awards = awards.map((a) {
      return a.award;
    }).toList();
    widget.collectionInfo.loaded = true;
    widget.collectionInfo.lastLoaded = DateTime.now().microsecondsSinceEpoch;
    final prefs = await SharedPreferences.getInstance();
    List<Map> amaps = [];
    for (Award a in widget.collectionInfo.awards) {
      amaps.add(awardToJson(a));
    }
    prefs.setString(
        widget.collectionInfo.docRef.documentID,
        jsonEncode(
            {"awards": amaps, "lastLoaded": widget.collectionInfo.lastLoaded}));
  }

  Future<bool> auditDocument() async {
    if (auditing) {
      return false;
    }
    auditing = true;
    Map collection = (await widget.collectionInfo.docRef.get()).data;
    String url = collection['googledoc'];

    if (url == null) {
      auditing = false;
      return false;
    }
    Result result = await retrieveAwards(url);
    Map<int, Award> inServer = Map();
    awards.forEach((a) {
      if (a.award.fromDoc) {
        if (inServer[a.award.hash] != null) {
          Firestore.instance.document(a.award.docPath).delete();
        } else {
          inServer[a.award.hash] = a.award;
        }
      }
    });
    Map<int, Award> inDoc = Map();
    result.awards.forEach((a) {
      if (a.fromDoc) {
        if (inServer[a.hash] == null) {
          inDoc[a.hash] = a;
        } else {
          inServer.remove(a.hash);
        }
      }
    });
    if (inServer.length > 0 || inDoc.length > 0) {
      updated = true;
      widget.collectionInfo.docRef
          .updateData({'lastEdit': DateTime.now().microsecondsSinceEpoch});
    }

    inDoc.forEach((dHash, dAward) {
      dAward.showYear = false;
      uploadAward(widget.collectionInfo.docRef.path + "/document_awards",
          dAward, widget.collectionInfo.docRef, false);

      widget.collectionInfo.docRef.setData({
        "googledoc": url,
        "lastEdit": DateTime.now().microsecondsSinceEpoch,
        "awardEdits": {dHash.toString(): DateTime.now().microsecondsSinceEpoch}
      }, merge: true);
    });
    inServer.forEach((sHash, sAward) {
      Firestore.instance.document(sAward.docPath).delete();
    });
    auditing = false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.shouldLoad.value) {
      refresh();
    }

    return SliverList(
        delegate: SliverChildListDelegate(
      mostRecent
          ? awards.map((a) {
              return a.buildCard(context, true);
            }).toList()
          : awards
              .map((a) {
                return a.buildCard(context, true);
              })
              .toList()
              .reversed
              .toList(),
    ));
  }
}
