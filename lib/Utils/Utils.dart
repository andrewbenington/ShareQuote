import 'package:flutter/material.dart';

class PrimitiveWrapper {
  var value;
  PrimitiveWrapper(this.value);
}

void rebuildAllChildren(BuildContext context) {
  void rebuild(Element el) {
    el.markNeedsBuild();
    el.visitChildren(rebuild);
  }
  (context as Element).visitChildren(rebuild);
}