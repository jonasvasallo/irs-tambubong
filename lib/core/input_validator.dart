import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';

class InputValidator {
  static String? Function(String?)? requiredValidator = (value) =>
      (value != null && value.length <= 0) ? 'This field is required' : null;

  static String? Function(String?)? emailValidator = (value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    } else if (!EmailValidator.validate(value)) {
      return 'Enter a valid email address';
    }
    return null; // Return null if validation succeeds
  };

  static String? Function(String?)? passwordValidator = (value) =>
      value != null && value.length < 8 ? 'Enter min. 8 characters' : null;

  static String? Function(String?)? phoneValidator = (value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Define the regex pattern for the desired format: +63 9XX-XXX-XXXX
    RegExp regex = RegExp(r'^\+63 9\d{2}-\d{3}-\d{4}$');

    if (!regex.hasMatch(value)) {
      return 'Enter a valid phone number (+63 9XX-XXX-XXXX)';
    }

    return null; // Return null if validation succeeds
  };

  static checkFormValidity(formKey, context) {
    final isValid = formKey.currentState!.validate();
    if (!isValid) {
      return;
    }
  }
}
