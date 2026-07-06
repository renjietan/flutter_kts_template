import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class SimpleFormTextField extends StatefulWidget {
  final FormFieldConfig field;
  final Color? fillColor;
  final double? labelFontSize;

  const SimpleFormTextField({
    super.key,
    required this.field,
    this.fillColor = const Color(0x9921262C),
    this.labelFontSize = 14,
  });

  @override
  State<SimpleFormTextField> createState() => _SimpleFormTextFieldState();
}

class _SimpleFormTextFieldState extends State<SimpleFormTextField> {
  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: widget.field.name,
      controller: widget.field.textEditingController,
      obscureText: widget.field.obscureText,
      keyboardType: widget.field.keyboardType,
      validator: widget.field.validators != null
          ? FormBuilderValidators.compose(widget.field.validators!)
          : null,
      decoration: InputDecoration(
        labelText: widget.field.hintText ?? widget.field.label,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        labelStyle: TextStyle(
          color: Colors.white,
          fontSize: (widget.labelFontSize ?? 13),
        ),
        hintStyle: TextStyle(
          color: Colors.white,
          fontSize: (widget.labelFontSize ?? 13),
        ),
        filled: true,
        fillColor: widget.fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: Color(0xFF404040)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: Color(0xFF404040)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: Color(0xFF64B5F6)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}

class FormFieldConfig {
  final String name;
  final String label;
  final String? hintText;
  final List<FormFieldValidator<String>>? validators;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextEditingController? textEditingController;

  FormFieldConfig({
    required this.name,
    required this.label,
    this.hintText,
    this.validators,
    this.keyboardType,
    this.obscureText = false,
    this.textEditingController,
  });
}
