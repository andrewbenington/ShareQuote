import 'package:cloud_firestore/cloud_firestore.dart';

import 'Award.dart';

class Collection {
  Collection({this.docRef});
  DocumentReference docRef;
  int lastLoaded = 0;
  bool loaded = false;
  List<Award> awards = [];
}