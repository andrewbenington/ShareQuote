import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:pearawards/Utils/Converter.dart';
import 'package:pearawards/Utils/LocalData.dart';
import 'package:pearawards/Utils/Upload.dart';
import 'package:pearawards/Utils/Utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;

import 'Award.dart';
import 'package:pearawards/Collections/Collection.dart';

int currentIndex = 0;

class AwardsStream extends StatefulWidget {
  AwardsStream(
      {Key key,
      this.docRef,
      this.directReferences = false,
      this.collectionInfo,
      this.shouldLoad,
      this.refreshParent,
      this.directoryName = "awards",
      this.isLoading,
      this.noAwards,
      this.numAwards,
      this.filter,
      this.mostRecent,
      this.searchText})
      : super(key: key);

  final bool directReferences;
  final Collection collectionInfo;
  final DocumentReference docRef;
  final String directoryName;
  final Function refreshParent;

  final PrimitiveWrapper shouldLoad;
  final PrimitiveWrapper isLoading;
  final PrimitiveWrapper noAwards;
  final PrimitiveWrapper numAwards;
  final PrimitiveWrapper filter;
  final PrimitiveWrapper mostRecent;
  final PrimitiveWrapper searchText;

  @override
  _AwardsStreamState createState() => _AwardsStreamState();
}

class _AwardsStreamState extends State<AwardsStream> {
  TextEditingController urlController = TextEditingController();

  bool error = false;
  bool mostRecent = true;
  bool populateMap = false;
  bool auditing = false;
  bool updated = false;

  List<AwardLoader> awards;

  PrimitiveWrapper loaded = PrimitiveWrapper(0);
  PrimitiveWrapper downloaded = PrimitiveWrapper(0);

  Map lastEdits;
  int total = 0;

  @override
  void initState() {
    super.initState();
    awards = [];
    loadFromMemory();
  }

  refresh() async {
    print(globals.reads);
    auditing = false;
    if (!widget.isLoading.value) {
      await loadAwards();
      if (widget.collectionInfo != null && await auditDocument()) {
        loadAwards();
      }
    }
  }

  loadFromMemory() async {
    globals.loadedAwards = await LocalData.storedAwards.then((awards) {
      return awards;
    });
    refresh();
  }

  loadAwards() async {
    downloaded.value = 0;
    loaded.value = 0;
    widget.isLoading.value = true;

    DocumentSnapshot dSnapshot = await widget.docRef.get();
    globals.reads++;

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
            snap: docs.documents[index],
            refresh: widget.refreshParent,
            downloaded: downloaded);
      });

      if (widget.numAwards != null) {
        widget.numAwards.value = awards.length;
      }
      awards.sort((a, b) {
        return b.award.timestamp - a.award.timestamp;
      });

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
                refresh: widget.refreshParent,
                downloaded: downloaded);
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
      }
    }
    loaded.value = 0;
    awards = [];
    QuerySnapshot snapshot =
        await widget.docRef.collection(widget.directoryName).getDocuments();
    total = snapshot.documents.length;
    if (snapshot.documents.length == 0) {
      widget.noAwards.value = true;
      widget.isLoading.value = false;
      widget.shouldLoad.value = false;
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
          reference: doc.data["reference"] is String
              ? Firestore.instance.document(doc.data["reference"])
              : doc.data["reference"],
          numLoaded: loaded,
          lastEdit: lastEdits[doc.documentID],
          refresh: widget.refreshParent,
          downloaded: downloaded);
      initAward(loader);
    }
  }

  initAward(AwardLoader loader) async {
    if (mounted) {
      setState(() {});
    }

    await loader.loadAward();
    awards.add(loader);
    if (awards.length >= total) {
      awards.sort((a, b) {
        if (a == null || b == null || a.award == null || b.award == null) {
          return 0;
        }
        return b.award.timestamp - a.award.timestamp;
      });
      if (widget.collectionInfo != null) {
        //storeAwards();
      }
    }
    if (awards.length >= total) {
      widget.isLoading.value = false;
      widget.shouldLoad.value = false;
      if (awards.length > 0) {
        widget.noAwards.value = false;
      }
      if (awards.length > 0) {
        initEdits();
      }
      if (widget.refreshParent != null) {
        //widget.refreshParent();
      }
      if (mounted) {
        setState(() {});
      }
      LocalData.writeAwards(globals.loadedAwards.values.toList());
      print("Downloaded ${downloaded.value} awards from server");
    }
  }

  initEdits() async {
    Map data = (await widget.docRef.get()).data;
    globals.reads++;
    int lastEdit = data["lastEdit"];
    if (lastEdit == null) {
      await widget.docRef.setData(
          {"lastEdit": DateTime.now().microsecondsSinceEpoch},
          merge: true);
    }
    for (AwardLoader a in awards) {
      if (lastEdits[a.award.hash.toString()] == null) {
        lastEdits[a.award.hash.toString()] =
            DateTime.now().microsecondsSinceEpoch;
      }
    }

    widget.docRef.setData({"awardEdits": lastEdits}, merge: true);
  }

  storeAwards() async {
    LocalData.writeAwards(globals.loadedAwards.values.toList());
  }

  Future<bool> auditDocument() async {
    if (auditing) {
      return false;
    }
    auditing = true;
    Map collection = (await widget.collectionInfo.docRef.get()).data;
    globals.reads++;
    String url = collection['googledoc'];

    if (url == null) {
      auditing = false;
      return false;
    }
    Result result = await retrieveAwards(url);
    if (awards.length == 0 ||
        result.awards.length == 0 ||
        (result.awards.length - awards.length).abs() > awards.length * 0.1) {
      return false;
    }
    Map<int, Award> inServer = Map();
    awards.forEach((a) {
      if (a.award != null && a.award.fromDoc) {
        if (inServer[a.award.hash] != null) {
          Firestore.instance.document(a.award.docPath).delete();
        } else {
          inServer[a.award.hash] = a.award;
        }
      }
    });
    Map<int, Award> inDoc = Map();
    if (result == null) {
      print('error');
      return null;
    }
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
      uploadAward(widget.collectionInfo.docRef.path + "/document_awards",
          dAward, widget.collectionInfo.docRef, false);

      widget.collectionInfo.docRef.setData({
        "googledoc": url,
        "lastEdit": DateTime.now().microsecondsSinceEpoch,
        "awardEdits": {dHash.toString(): DateTime.now().microsecondsSinceEpoch}
      }, merge: true);
    });
    inServer.forEach((sHash, sAward) {
      globals.loadedAwards.remove(sAward.hash.toString());
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

    return awards.length == 0
        ? SliverFillRemaining(
            child: Column(
              children: <Widget>[
                Spacer(),
                widget.isLoading.value
                    ? CircularProgressIndicator()
                    : Text(
                        'Nothing to see here',
                        style: TextStyle(
                            color: globals.theme.backTextColor,
                            fontSize: 40,
                            fontWeight: FontWeight.bold),
                      ),
                Spacer()
              ],
            ),
          )
        : SliverList(
            delegate: SliverChildListDelegate(
            widget.searchText != null && widget.searchText.value != null
                ? widget.mostRecent.value
                    ? awards.map((a) {
                        return a.buildCard(context, true, widget.filter.value);
                      }).where((test) {
                        if (!(test is AwardCard)) {
                          return false;
                        }
                        var loader = test as AwardCard;
                        return loader.award != null &&
                            loader.award.contains(widget.searchText.value);
                      }).toList()
                    : awards
                        .map((a) {
                          return a.buildCard(
                              context, true, widget.filter.value);
                        })
                        .toList()
                        .reversed
                        .where((test) {
                          if (!(test is AwardCard)) {
                            return false;
                          }
                          var loader = test as AwardCard;
                          return loader.award != null &&
                              loader.award.contains(widget.searchText.value);
                        })
                        .toList()
                : mostRecent
                    ? awards.map((a) {
                        return a.buildCard(context, true, widget.filter.value);
                      }).toList()
                    : awards
                        .map((a) {
                          return a.buildCard(
                              context, true, widget.filter.value);
                        })
                        .toList()
                        .reversed
                        .toList(),
          ));
  }
}
