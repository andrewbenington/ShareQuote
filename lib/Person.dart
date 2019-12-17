// import 'package:flutter/material.dart';
// import 'package:pearawards/Converter.dart';
// import 'package:pearawards/AwardsStream.dart';

// import 'Award.dart';

// class PersonPage extends StatefulWidget {
//   PersonPage({Key key, this.name}) : super(key: key);

//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.

//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".

//   final Name name;

//   @override
//   _PersonPageState createState() => _PersonPageState(name: name);
// }

// class _PersonPageState extends State<PersonPage> {
//   _PersonPageState({this.name});
//   final Name name;
//   bool mostRecent = true;

//   @override
//   Widget build(BuildContext context) {
//     // This method is rerun every time setState is called, for instance as done
//     // by the _incrementCounter method above.
//     //
//     // The Flutter framework has been optimized to make rerunning build methods
//     // fast, so that you can just rebuild anything that needs updating rather
//     // than having to individually change instances of widgets.
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.green,
//         // Here we take the value from the MyHomePage object that was created by
//         // the App.build method, and use it to set our appbar title.
//         title: Text(name.first + ((name.last == null) ? "" : " " + name.last)),
//       ),
//       backgroundColor: Colors.green[300],
//       body: Center(
//         // Center is a layout widget. It takes a single child and positions it
//         // in the middle of the parent.
//         child: ListView.builder(
//             itemCount: awards.length,
//             itemBuilder: (BuildContext ctxt, int index) {
//               if (mostRecent) {
//                 index = awards.length - index - 1;
//               }
//               bool add = false;
//               for (Line l in awards[index].quotes) {
//                 if (l.isQuote()) {
//                   Quote q = l;
//                   if (q.name != null &&
//                       q.name.first == name.first &&
//                       q.name.last == name.last) {
//                     add = true;
//                     break;
//                   }
//                 } else {
//                   break;
//                 }
//               }
//               return add ? buildAwardCard(context, awards[index], true) : Container();
//             }),
//       ),
//     );
//   }
// }
