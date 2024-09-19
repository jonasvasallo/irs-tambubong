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

  static String? Function(String?)? passwordValidator = (value) {
    if (value == null || value.isEmpty) {
      return 'Password cannot be empty';
    }

    if (value.length < 12) {
      return 'Enter min. 12 characters';
    }

    final hasUppercase = value.contains(RegExp(r'[A-Z]'));
    final hasLowercase = value.contains(RegExp(r'[a-z]'));
    final hasDigits = value.contains(RegExp(r'\d'));
    final hasSpecialCharacters =
        value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (!hasUppercase) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!hasLowercase) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!hasDigits) {
      return 'Password must contain at least one digit';
    }

    if (!hasSpecialCharacters) {
      return 'Password must contain at least one special character';
    }

    return null; // Password is strong
  };

  static String? Function(String?)? phoneValidator = (value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Define the regex pattern for the desired format: +63 9XX-XXX-XXXX
    RegExp regex = RegExp(r'^\+639\d{2}\d{3}\d{4}$');

    if (!regex.hasMatch(value)) {
      return 'Enter a valid phone number (+639XXXXXXXXX)';
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
