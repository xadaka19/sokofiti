import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';

class Validator {
  static String emailPattern =
      r"(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'"
      r'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-'
      r'\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*'
      r'[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4]'
      r'[0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9]'
      r'[0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\'
      r'x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])';

  static String? validateEmail({String? email, required BuildContext context}) {
    if ((email ??= "").trim().isEmpty) {
      return "pleaseEnterMail".translate(context);
    } else if (!RegExp(emailPattern).hasMatch(email)) {
      return "pleaseEnterValidEmailAddress".translate(context);
    } else {
      return null;
    }
  }

  static String? emptyValueValidation(
    String? value, {
    String? errmsg,
    required BuildContext context,
  }) {
    errmsg ??= 'pleaseEnterSomeText'.translate(context);

    return (value ?? "").trim().isEmpty ? errmsg : null;
  }

  static String? validatePhoneNumber({
    String? value,
    required BuildContext context,
    required bool isRequired,
  }) {
    // If the field is required and the value is empty
    if (isRequired && (value ??= "").trim().isEmpty) {
      return "pleaseEnterValidPhoneNumber".translate(context);
    }

    // If value is empty and not required, return null
    if (value!.trim().isEmpty) {
      return null;
    }

    // Validate Safaricom number
    return validateSafaricomNumber(value: value, context: context);
  }

  static String? validateSafaricomNumber({
    required String value,
    required BuildContext context,
  }) {
    log('🔍 Validating Safaricom number: $value', name: 'SafaricomValidator');

    // Remove all spaces, dashes, and parentheses
    String cleanNumber = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    log('  Cleaned number: $cleanNumber', name: 'SafaricomValidator');

    // Safaricom prefixes (without country code)
    // 07XX series: 0700-0709, 0710-0719, 0720-0729, 0740-0749, 0757-0759, 0768-0769, 0790-0799
    final safaricomPrefixes = [
      '0700', '0701', '0702', '0703', '0704', '0705', '0706', '0707', '0708', '0709',
      '0710', '0711', '0712', '0713', '0714', '0715', '0716', '0717', '0718', '0719',
      '0720', '0721', '0722', '0723', '0724', '0725', '0726', '0727', '0728', '0729',
      '0740', '0741', '0742', '0743', '0744', '0745', '0746', '0747', '0748', '0749',
      '0757', '0758', '0759',
      '0768', '0769',
      '0790', '0791', '0792', '0793', '0794', '0795', '0796', '0797', '0798', '0799',
    ];

    // Check if number starts with country code (+254 or 254)
    if (cleanNumber.startsWith('+254')) {
      cleanNumber = '0' + cleanNumber.substring(4);
      log('  Converted from +254 to: $cleanNumber', name: 'SafaricomValidator');
    } else if (cleanNumber.startsWith('254')) {
      cleanNumber = '0' + cleanNumber.substring(3);
      log('  Converted from 254 to: $cleanNumber', name: 'SafaricomValidator');
    }

    // Check if number is 10 digits starting with 0
    if (!RegExp(r'^0\d{9}$').hasMatch(cleanNumber)) {
      log('  ❌ FAILED: Not 10 digits starting with 0', name: 'SafaricomValidator');
      return "Please enter a valid 10-digit Safaricom number";
    }

    // Check if number starts with a valid Safaricom prefix
    bool isValidSafaricom = safaricomPrefixes.any((prefix) => cleanNumber.startsWith(prefix));

    if (!isValidSafaricom) {
      log('  ❌ FAILED: Not a Safaricom prefix (${cleanNumber.substring(0, 4)})', name: 'SafaricomValidator');
      return "Only Safaricom numbers are allowed (07XX)";
    }

    log('  ✅ VALID Safaricom number!', name: 'SafaricomValidator');
    return null;
  }

  static String? validateName(
    String? value, {
    String? errmsg,
    required BuildContext context,
  }) {
    errmsg ??= 'pleaseEnterSomeText'.translate(context);
    final pattern = RegExp(r'^[a-zA-Z ]+$');
    if ((value ??= "").trim().isEmpty) {
      return errmsg;
    } else if (!pattern.hasMatch(value)) {
      return 'pleaseEnterOnlyAlphabets'.translate(context);
    } else {
      return null;
    }
  }

  static String? nullCheckValidator(
    String? value, {
    int? requiredLength,
    required BuildContext context,
  }) {
    if (value!.isEmpty) {
      return "fieldMustNotBeEmpty".translate(context);
    } else if (requiredLength != null) {
      if (value.length < requiredLength) {
        return "${"textMustBe".translate(context)} $requiredLength ${"characterLong".translate(context)}";
      } else {
        return null;
      }
    }

    return null;
  }

  static String? validateSlug(String? slug, {required BuildContext context}) {
    final RegExp slugRegExp = RegExp(
      r'^[a-z0-9]+(-[a-z0-9]+)*$',
      unicode: true,
    );

    // If slug is null or empty, return null (no validation needed)
    if (slug == null || slug.isEmpty) {
      return null; // Slug is optional, no validation
    }

    // If slug is not empty, validate it against the pattern
    if (!slugRegExp.hasMatch(slug)) {
      return "slugWarning".translate(context); // Customize the warning message
    }

    return null; // Slug is valid
  }

  static String? validatePassword(
    String? password, {
    String? secondFieldValue,
    required BuildContext context,
  }) {
    if (password!.isEmpty) {
      return "fieldMustNotBeEmpty".translate(context);
    } else if (password.length < 8) {
      return "passwordWarning".translate(context);
    }
    if (secondFieldValue != null) {
      if (password != secondFieldValue) {
        return "fieldSameWarning".translate(context);
      }
    }

    return null;
  }

  static String? urlValidation({String? value, required BuildContext context}) {
    if (value!.isNotEmpty) {
      validUrl(value).then((result) {
        if (result == false) {
          return 'plzValidUrlLbl'.translate(context);
        } else {
          return result;
        }
      });
    } else {
      return null;
    }
    return null;
  }

  static Future<bool> validUrl(String value) async {
    try {
      Response response = await Dio().head(value);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class CustomValidator<T> extends FormField<T> {
  CustomValidator({
    super.key,
    required FormFieldValidator<T> super.validator,
    required Widget Function(FormFieldState<T> state) builder,
    super.initialValue,
    bool autovalidate = false,
  }) : super(
         builder: (FormFieldState<T> state) {
           return builder(state);
         },
       );
}
