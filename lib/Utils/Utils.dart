import 'dart:convert';

import 'package:flutter/material.dart';

class PrimitiveWrapper {
  dynamic value = false;
  PrimitiveWrapper(this.value);
}

void rebuildAllChildren(BuildContext context) {
  void rebuild(Element el) {
    el.markNeedsBuild();
    el.visitChildren(rebuild);
  }

  (context as Element).visitChildren(rebuild);
}

String incrementString(String s) {
  if (s == "" || s == null) {
    return null;
  }
  AsciiCodec codec = AsciiCodec();
  List<int> list;
  try {
    list = codec.encode(s);
  } catch (e) {
    return null;
  }

  if (list[list.length - 1] > 127) {
    return null;
  } else {
    String incremented;
    if (list[list.length - 1] == 127) {
      incremented = incrementString(s.substring(0, s.length - 1)) + '\0';
    } else {
      incremented = s.substring(0, s.length - 1) +
          codec.decode([list[list.length - 1] + 1]);
    }
    print('incremented $s to $incremented');
    return incremented;
  }
}
