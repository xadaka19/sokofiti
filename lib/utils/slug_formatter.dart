import 'package:flutter/services.dart';

class SlugFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // force lowercase
    text = text.toLowerCase();

    // replace non-alphanumeric with "-"
    text = text.replaceAll(RegExp(r'[^a-z0-9]+'), '-');

    // collapse multiple "-"
    text = text.replaceAll(RegExp(r'-{2,}'), '-');

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
