import 'package:flutter/material.dart';

extension Gap on num {
  Widget get vGap => SizedBox(height: this.toDouble());

  Widget get hGap => SizedBox(width: this.toDouble());
}
