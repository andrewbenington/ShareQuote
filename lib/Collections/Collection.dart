import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:pearawards/Awards/Award.dart';

class Collection {
  Collection({this.docRef, this.title, this.owner, this.lastEdited});
  DocumentReference docRef;
  int lastLoaded = 0;
  int lastEdited = 0;
  bool loaded = false;
  List<Award> awards = [];
  String title;
  String owner;
}