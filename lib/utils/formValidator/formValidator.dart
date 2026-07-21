import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class FormValidator {
  static FormFieldValidator<String> ipPortValidator({
    int portMin = 1,
    int portMax = 65535,
    String? errorText,
  }) {
    return (String? rawInput) {
      if (rawInput == null || rawInput.isEmpty) return null;

      final segments = rawInput.split(':');
      if (segments.length != 2) {
        return errorText ?? '';
      }

      final ipAddress = segments[0];
      final portNumber = segments[1];

      final ipError = FormBuilderValidators.ip()(ipAddress);
      if (ipError != null) {
        return errorText ?? '';
      }

      // 校验端口（不传 errorText）
      final portError = FormBuilderValidators.portNumber(
        min: portMin,
        max: portMax,
      )(portNumber);
      if (portError != null) {
        return errorText ?? '';
      }

      return null;
    };
  }
}
