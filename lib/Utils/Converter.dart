import 'package:http/http.dart';

import 'package:pearawards/Awards/Award.dart';

String awardTitle = "";

enum CurrentState {
  unknown,
  year,
  award,
  quote,
  names,
  action,
  title,
}

class Result {
  List<Award> awards;
  String error;
  String title;
  bool success = true;
}

Future<Result> retrieveAwards(String url) async {
  String file;
  Result result = Result();
  if (url == null) {
    return null;
  }
  try {
    final response = await get(url);

    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON
      file = response.body;
    } else {
      // If that response was not OK, throw an error.
      throw Exception('Failed to load post');
    }
  } catch (e) {
    result.success = false;
    result.error = e.toString();
    return result;
  }

  result.awards = await convertAwards(file, url);
  result.title = awardTitle;
  return result;
}

Future<List<Award>> convertAwards(String file, String url) async {
  int currentYear = 0;
  List<Map> awards = [];
  Map currentAward = {};
  Map currentLine = {};
  List<Map> lines = [];
  List<Line> quotes = <Line>[];
  List<String> quoteLines = <String>[];
  List<Name> quoteNames = <Name>[];
  var currentState = CurrentState.unknown;
  String line;

  Name defaultName = Name(
    name: "",
  );

  while (awards.length == 0 ||
      (file.indexOf("<p") != -1 || file.indexOf("<ul") != -1) ||
      quotes.length != 0) {
    int index = 0;
    if (currentState != CurrentState.award) {
      if (file.indexOf("<div id=\"header\"") != -1) {
        line = file.substring(
            file.indexOf("<div id=\"header\""), file.indexOf("</div>"));
        file = file.substring(file.indexOf("</div>") + 4);
        currentState = CurrentState.title;
      } else if (file.indexOf("<ul") == -1 ||
          file.indexOf("<p") != -1 &&
              file.indexOf("<p") < file.indexOf("<ul ")) {
        line = file.substring(file.indexOf("<p"), file.indexOf("</p"));
        file = file.substring(file.indexOf("</p>") + 3);
      } else {
        line = file.substring(file.indexOf("<ul"), file.indexOf("</ul"));
        file = file.substring(file.indexOf("</ul>") + 3);
        currentState = CurrentState.names;
      }
    }

    while (currentState == CurrentState.unknown && index < line.length) {
      if (line[index] == '<') {
        while (line[index] != '>') {
          index++;
        }
      } else if (line.codeUnitAt(index) >= 48 && line.codeUnitAt(index) <= 57) {
        currentState = CurrentState.year;
        break;
      } else if (line[index] == '"' || line[index] == "“") {
        currentState = CurrentState.quote;
      } else if (index < line.length - 5 &&
          line.substring(index, index + 6) == '&quot;') {
        index += 5;
        currentState = CurrentState.quote;
      } else if (line[index] == '*' || line[index] == "(") {
        currentState = CurrentState.action;
      } else if (line[index] == '-') {
        currentState = CurrentState.names;
      }
      index++;
    }
    switch (currentState) {
      case CurrentState.title:
        String newTitle = "";
        while (index < line.length) {
          while (index < line.length && !isValidCharacter(line[index])) {
            index++;
          }
          if (line[index] == '<') {
            while (line[index] != '>') {
              index++;
            }
            index++;
          } else {
            if (line[index] == '\'') {}
            newTitle += line[index];
            index++;
          }
        }
        awardTitle = newTitle;
        currentState = CurrentState.unknown;
        break;
      case CurrentState.year:
        int newYear = 0;
        while (index < line.length &&
            line.codeUnitAt(index) >= 48 &&
            line.codeUnitAt(index) <= 57) {
          newYear *= 10;
          newYear += (line.codeUnitAt(index) - 48);
          index++;
        }
        if (newYear < 2100 && newYear > 2000) {
          currentYear = newYear;
        }
        currentState = CurrentState.unknown;
        break;
      case CurrentState.quote:
        String newQuote = "";
        bool quoteDone = false;

        while (!quoteDone) {
          if (index >= line.length) {
            line = file.substring(file.indexOf("<p"), file.indexOf("</p"));
            file = file.substring(file.indexOf("</p>") + 3);
            index = 0;
            newQuote += '\n';
          } else if (line[index] == '"' ||
              line[index] == '”' ||
              (index < line.length - 6 &&
                  line.substring(index, index + 6) == '&quot;') ||
              (index < line.length - 7 &&
                      line.substring(index + 1, index + 7) == '&quot;') &&
                  !isValidCharacter(line[index])) {
            quoteDone = true;
            index += 6;
            break;
          }
          if (line.codeUnitAt(index) > 50000 &&
              line.codeUnitAt(index) < 56000) {
            newQuote += line.substring(index, index + 2);
            index += 2;
          } else {
            while (index < line.length && !isValidCharacter(line[index])) {
              index++;
            }

            if (line[index] == '<') {
              while (line[index] != '>') {
                index++;
              }
              index++;
            } else {
              if (index < line.length - 5 &&
                  line.substring(index, index + 5) == '&#39;') {
                index += 5;
                newQuote += "\'";
              } else if (index < line.length - 4 &&
                  line.substring(index, index + 4) == '&gt;') {
                index += 4;
                newQuote += ">";
              } else {
                newQuote += line[index];
                index++;
              }
            }
          }
        }
        quoteLines.add(newQuote);
        quoteNames.add(defaultName);
        currentState = CurrentState.unknown;
        break;
      case CurrentState.action:
        String newAction = "";
        while (
            index < line.length && line[index] != '*' && line[index] != ')') {
          while (index < line.length && !isValidCharacter(line[index])) {
            index++;
          }
          if (line[index] == '<') {
            while (line[index] != '>') {
              index++;
            }
            index++;
          } else {
            if (line[index] == '\'') {}
            newAction += line[index];
            index++;
          }
        }
        quoteLines.add(newAction);
        quoteNames.add(null);
        currentState = CurrentState.unknown;
        break;
      case CurrentState.names:
        bool namesAdded = false;

        while (index < line.length) {
          if (namesAdded && line[index] == '<') {
            int nameIndex = 0;
            while (quoteNames.indexOf(defaultName) > -1) {
              quoteNames[quoteNames.indexOf(defaultName)] =
                  Name(name: quoteNames[nameIndex].name);
              nameIndex++;
            }
            for (int i = 0; i < quoteLines.length; i++) {
              Line l;
              if (quoteNames[i % quoteNames.length] != null) {
                int j = 0;
                while (quoteNames[(i + j) % quoteNames.length] == defaultName) {
                  j++;
                }
                l = Quote(
                  name: quoteNames[(i + j) % quoteNames.length],
                  message: quoteLines[i],
                );
              } else {
                l = Context(
                  message: quoteLines[i],
                );
              }
              quotes.add(l);
            }
            currentState = CurrentState.award;
            quoteLines = <String>[];

            quoteNames = <Name>[];
            break;
          }
          String name = "";
          String last = "";
          while (index < line.length) {
            while (index < line.length && !isValidCharacter(line[index])) {
              index++;
            }
            while (index < line.length && line[index] == ' ') {
              index++;
            }
            if (line[index] == '<') {
              while (line[index] != '>') {
                index++;
              }
              index++;
            } else {
              while (index < line.length &&
                  line[index] != '/' &&
                  line[index] != '<') {
                if (index < line.length - 5 &&
                    line.substring(index, index + 5) == '&#39;') {
                  index += 5;
                  name += "\'";
                } else {
                  name += line[index++];
                }
                if (index + 1 < line.length &&
                    line[index] == '.' &&
                    line[index + 1] == ' ') {
                  name += line[index++];
                }
              }
              if (line[index] == ' ') {
                index++;
              }
              break;
            }
          }
          /*if (line[index] != '/') {
            index++;
          }*/
          while (
              index < line.length && line[index] != '/' && line[index] != '<') {
            while (index < line.length && !isValidCharacter(line[index])) {
              index++;
            }
            if (line[index] != '<') {
              last += line[index++];
            }
          }
          int indexOf = quoteNames.indexOf(defaultName);
          if (indexOf == -1) {
            quoteNames.add(Name(name: name));
          } else {
            quoteNames[quoteNames.indexOf(defaultName)] = Name(name: name);
          }

          namesAdded = true;
          if (line[index] != '<') {
            index++;
          }
        }

        break;

      case CurrentState.award:
        if (quotes.length != 0) {
          List people = [];
          List quoteMaps = [];
          for (Line l in quotes) {
            if (l is Quote) {
              Quote q = l;
              if (people.indexOf(q.name.name.trim()) >= 0) {
                quoteMaps.add({
                  "quote": q.message,
                  "name": people.indexOf(q.name.name.trim())
                });
              } else {
                people.add({"name": q.name.name.trim(), "uid": null});
                quoteMaps.add({"quote": q.message, "name": people.length - 1});
              }
            } else {
              quoteMaps.add({"context": l.message});
            }
          }
          Map<String, dynamic> newAward = {
            "timestamp":
                DateTime(currentYear == 0 ? DateTime.now().year : currentYear)
                        .microsecondsSinceEpoch +
                    awards.length,
            "showYear": true,
            "people": people,
            "lines": quoteMaps,
            "fromdoc": true,
            "author": {"name": "Google Doc", "url": url}
          };
          awards.add(newAward);
        }
        quotes = <Line>[];

        currentState = CurrentState.unknown;
        break;

      case CurrentState.unknown:
        //print("should not be unknown");
        break;
    }
  }
  return awards.map((amap) {
    return Award.fromMap(amap);
  }).toList();
}

/*void printValidString(std::ofstream out, std::string s) {
    bool isValidCharacter(char c) ;
    for (char c : s) {
        if (isValidCharacter(c) && c != '"') {
            out << c;
        }
    }
}*/

bool isValidCharacter(String c) {
  return c == '’' ||
      c == '‘' ||
      c == '…' ||
      c.codeUnitAt(0) >= 32 && c.codeUnitAt(0) <= 126;
}

Map<String, dynamic> awardToMap(Award award) {
  Map<String, int> nameMap = Map.fromIterables(award.people.map((map) {
    return map["name"];
  }), award.people.map((map) {
    return award.people.indexOf(map);
  }));
  Map<String, int> uidMap = Map.fromIterables(award.people.map((map) {
    return map["uid"];
  }), award.people.map((map) {
    return award.people.indexOf(map);
  }));
  Map<String, dynamic> map = Map();
  map["lines"] = List<Map>();
  for (Line l in award.quotes) {
    Map lineMap = Map();
    if (l.isQuote()) {
      Quote q = l as Quote;
      if (q.name.uid != null && uidMap[q.name.uid] != null) {
        lineMap["name"] = uidMap[q.name.uid];
      } else if (nameMap[q.name.name] != null) {
        lineMap["name"] = nameMap[q.name.name];
      } else {
        print("error");
      }

      lineMap["quote"] = q.message;
    } else {
      lineMap["context"] = l.message;
    }
    map["lines"].add(lineMap);
  }
  map["people"] = award.people;
  Map author = Map();
  author["name"] = award.author.name;
  if (award.author.uid != null) {
    author["uid"] = award.author.uid;
  }
  map["author"] = author;
  map["timestamp"] = award.timestamp;
  map["fromdoc"] = award.fromDoc;
  map["showYear"] = award.showYear;
  map["nsfw"] = award.nsfw;
  map["docPath"] = award.docPath;
  map["likes"] = award.likes;
  map["liked"] = award.liked;
  map["lastLoaded"] = award.lastLoaded;
  return map;
}
