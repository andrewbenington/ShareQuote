import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pearawards/Awards/Award.dart';
import 'package:pearawards/Utils/Converter.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;

class LocalData {
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> get awardsFile async {
    final path = await _localPath;
    return File('$path/awards.txt');
  }

  static Future<File> writeAward(Award a) async {
    final file = await awardsFile;
    Map allAwards = jsonDecode(await file.readAsString());
    allAwards[a.hash] = jsonEncode(awardToMap(a));

    // Write the file
    return file.writeAsString(jsonEncode(allAwards));
  }

  static Future<File> writeAwards(List<Award> awardList) async {
    final file = await awardsFile;
    Map<String, dynamic> allAwards;
    if (!(await file.exists())) {
      allAwards = {};
    } else {
      String fileString = await file.readAsString();
      try {
        allAwards = jsonDecode(fileString);
      } catch (e) {
        allAwards = {};
        print(e);
      }
    }

    for (Award a in awardList) {
      try{
      allAwards[a.hash.toString()] = jsonEncode(awardToMap(a));} catch(error) {
        globals.loadedAwards.remove(a.hash.toString());
      }
    }
    // Write the file
    return file.writeAsString(jsonEncode(allAwards));
  }

  static Future<Award> readAward(String hash) async {
    final file = await awardsFile;
    Map allAwards = jsonDecode(await file.readAsString());
    String jsonString = allAwards[hash];
    if (jsonString == null) {
      return null;
    }
    // Write the file
    return Award.fromMap(jsonDecode(jsonString));
  }

  static Future<Map<String, Award>> get storedAwards async {
    final file = await awardsFile;
    List<String> brokenAwards = [];
    if (!(await file.exists())) {
      return null;
    }
    Map allAwards = jsonDecode(await file.readAsString());
    Map<String, Award> awards = Map();
    allAwards.forEach((hash, jsonString) {
      try {
        Award a = Award.fromMap(jsonDecode(jsonString));
        awards[hash] = a;
      } catch (error) {
        brokenAwards.add(hash);
      }
    });
    cleanStored(brokenAwards);
    // Write the file
    return awards;
  }

  static cleanStored(List<String> toRemove) async {
    final file = await awardsFile;
    if (!(await file.exists())) {
      return null;
    }
    Map allAwards = jsonDecode(await file.readAsString());
    for (String hash in toRemove) {
      allAwards.remove(hash);
      globals.loadedAwards.remove(hash);
    }
    return file.writeAsString(jsonEncode(allAwards));
  }
}
