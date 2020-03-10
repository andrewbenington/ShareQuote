import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Collections/CollectionStream.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;
import 'package:shared_preferences/shared_preferences.dart';

import 'Collection.dart';

createCollection(String name) async {
  DocumentReference document =
      Firestore.instance.collection('collections').document();
  await document.setData({
    "lastEdit": DateTime.now().microsecondsSinceEpoch,
    "name": name,
    "owner": globals.me.uid,
    "followers": {globals.me.uid: true}
  });
  globals.loadedCollections[document.documentID] = Collection(
      docRef: document,
      owner: globals.me.uid,
      title: name,
      lastEdited: DateTime.now().microsecondsSinceEpoch);
  await addCollectionReference(document, name, null);
}

Future<void> addCollectionReference(
    DocumentReference document, String title, Function onComplete) async {
  var docRef = Firestore.instance.document('users/${globals.me.uid}');

  docRef.get().then((doc) {
    globals.reads++;
    document.updateData({
      "followers": {globals.me.uid: true}
    });
    var coll = Firestore.instance
        .collection('users/${globals.me.uid}/collections')
        .document();
    coll.get().then((doc) {
      globals.reads++;
      if (!doc.exists) {
        Firestore.instance
            .document(
                'users/${globals.me.uid}/collections/${document.documentID}')
            .setData({
          "reference": document,
          "name": title,
        });
      }
    });
    globals.loadedCollections[document.documentID] = Collection(
        docRef: document,
        lastEdited: doc.data["lastEdit"],
        title: title,
        owner: doc.documentID);
    if (onComplete != null) {
      onComplete();
    }
  });
}

Future<void> removeCollectionReference(DocumentReference document) async {
  document.updateData({
    "followers": {globals.me.uid: false}
  });
  Firestore.instance
      .document(
          'users/${globals.me.uid}/collections/${document.documentID}')
      .delete();
  deleteAwardsFromMemory(document.documentID);
  globals.loadedCollections.remove(document.documentID);
}

deleteCollection(DocumentReference docRef) async {
  await deleteAwardsFromMemory(docRef.documentID);
  globals.loadedCollections.remove(docRef.documentID);
  docRef.collection('awards').getDocuments().then((snapshot) {
    for (DocumentSnapshot ds in snapshot.documents) {
      ds.reference.delete();
    }
  });
  docRef.collection('document_awards').getDocuments().then((snapshot) {
    for (DocumentSnapshot ds in snapshot.documents) {
      deleteComments(ds.reference.collection("comments"));
      ds.reference.delete();
    }
  });
  docRef.delete();
}

deleteComments(CollectionReference colRef) async {
  QuerySnapshot comments = await colRef.getDocuments();

  for (DocumentSnapshot ds in comments.documents) {
    ds.reference.delete();
  }
}

deleteAwardsFromMemory(String docID) async {
  final prefs = (await SharedPreferences.getInstance());
  prefs.remove(docID);
}

Future<void> loadCollectionFromReference(
    DocumentReference collection, DocumentReference reference) async {
  DocumentSnapshot document = await collection.get();
  globals.reads++;
  if (!document.exists) {
    reference.delete();
    globals.loadedCollections.remove(document.documentID);
    return;
  }
  globals.loadedCollections[document.documentID] = Collection(
      docRef: document.reference,
      title: document.data["name"] == null ? "" : document.data["name"],
      owner: document.data["owner"],
      lastEdited: document.data["lastEdit"] == null
          ? DateTime.now().microsecondsSinceEpoch
          : document.data["lastEdit"]);
}

pushCollectionStream(
    BuildContext context, Collection c, Function onChanged) async {
  if (await Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => CollectionStream(
        collectionInfo: c,
        title: c.title,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
            scale: animation.drive(CurveTween(curve: Curves.ease)),
            alignment: Alignment.center,
            child: child);
      },
    ),
  )) {
    onChanged();
  }
}
