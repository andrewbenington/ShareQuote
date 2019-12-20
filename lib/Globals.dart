library sharequote.globals;

import 'package:firebase_auth/firebase_auth.dart';

import 'Collection.dart';

FirebaseAuth firebaseAuth;
FirebaseUser firebaseUser;

Map<String, Collection> loadedCollections = Map();