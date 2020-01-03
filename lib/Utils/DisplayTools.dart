import 'dart:ui';

import 'package:flutter/widgets.dart';

var days = <String>[
  "Sunday",
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday"
];

var months = <String>[
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
];

String formatDateTimeComplete(DateTime dt) {
  return DateTime.now().difference(dt).inDays > 6
      ? months[dt.month - 1] +
          " " +
          dt.day.toString() +
          (dt.year == DateTime.now().year ? "" : ", " + dt.year.toString())
      : (DateTime.now().weekday == dt.weekday &&
                  DateTime.now().difference(dt).inDays < 1
              ? "Today"
              : (DateTime.now().weekday - dt.weekday) % 7 == 1
                  ? "Yesterday"
                  : days[dt.weekday == 7 ? 0 : dt.weekday]) +
          ", " +
          ((dt.hour == 0 || dt.hour == 12)
              ? "12"
              : dt.hour > 11 ? (dt.hour - 12).toString() : dt.hour.toString()) +
          ":" +
          dt.minute.toString().padLeft(2, '0') +
          " " +
          (dt.hour > 11 ? "pm" : "am");
}

String formatDateTimeShort(DateTime dt) {
  return DateTime.now().difference(dt).inDays > 6
      ? months[dt.month - 1] +
          " " +
          dt.day.toString() +
          (dt.year == DateTime.now().year ? "" : ", " + dt.year.toString())
      : (DateTime.now().weekday == dt.weekday &&
              DateTime.now().difference(dt).inDays < 1
          ? ((dt.hour == 0 || dt.hour == 12)
                  ? "12"
                  : dt.hour > 11
                      ? (dt.hour - 12).toString()
                      : dt.hour.toString()) +
              ":" +
              dt.minute.toString().padLeft(2, '0') +
              " " +
              (dt.hour > 11 ? "pm" : "am")
          : (DateTime.now().weekday - dt.weekday) % 7 == 1
              ? "Yesterday"
              : days[dt.weekday == 7 ? 0 : dt.weekday]);
}

String formatDateTimeAward(DateTime dt) {
  return DateTime.now().difference(dt).inDays > 6
      ? "on " +
          months[dt.month - 1] +
          " " +
          dt.day.toString() +
          (dt.year == DateTime.now().year ? "" : ", " + dt.year.toString())
      : (DateTime.now().weekday == dt.weekday &&
              DateTime.now().difference(dt).inDays < 1
          ? "at " +
              ((dt.hour == 0 || dt.hour == 12)
                  ? "12"
                  : dt.hour > 11
                      ? (dt.hour - 12).toString()
                      : dt.hour.toString()) +
              ":" +
              dt.minute.toString().padLeft(2, '0') +
              " " +
              (dt.hour > 11 ? "pm" : "am")
          : (DateTime.now().weekday - dt.weekday) % 7 == 1
              ? "Yesterday"
              : days[dt.weekday == 7 ? 0 : dt.weekday]);
}

Color colorFromID(String id) {
  return HSLColor.fromAHSL(1, intFromString(id) % 360.0, 0.8, 0.55).toColor();
}

String getChatName(String id1, String id2) {
  return id1.compareTo(id2) > 0 ? id2 + id1 : id1 + id2;
}

int intFromString(String s) {
  int result = 1;
  var units = s.codeUnits;
  for (int i = 0; i < units.length; i++) {
    result += (units[i] - 50) % 150;
  }
  return result;
}
