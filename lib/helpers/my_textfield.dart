import 'package:flutter/material.dart';

class MyTextfield extends StatefulWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;
  final int? maxLines;
  final String? prefixText;

  const MyTextfield({
    super.key,
    required this.hintText,
    required this.obscureText,
    required this.controller,
    this.maxLines,
    this.prefixText,
  });

  @override
  State<MyTextfield> createState() => _MyTextfieldState();
}

class _MyTextfieldState extends State<MyTextfield> {
  late bool _isObscured;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
    _focusNode = FocusNode();

    // Listen for focus changes 
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isObscured == true) {
        setState(() {
          _isObscured = true; // Reset to obscure when focus is lost
        });
      } else {
        setState(() {}); // Trigger UI update when focused
      }
    });
  }

  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _isObscured,
      maxLines: widget.maxLines,
      focusNode: _focusNode,
      cursorColor: Theme.of(context).colorScheme.tertiary,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.secondary),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.tertiary),
          borderRadius: BorderRadius.circular(15),
        ),
        border: OutlineInputBorder(),
        hintText: widget.hintText,
        hintStyle:
            TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
        fillColor: Theme.of(context).colorScheme.primary,
        filled: true,
        prefixText: widget.prefixText, // Ensure prefixText is included
        prefixStyle: TextStyle(
            color: Theme.of(context).colorScheme.tertiary, fontSize: 15),
        suffixIcon: widget.obscureText && _focusNode.hasFocus
            ? IconButton(
                icon: Icon(
                  _isObscured ? Icons.visibility_off : Icons.visibility,
                  size: 22,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                onPressed: () {
                  setState(() {
                    _isObscured = !_isObscured; // Toggle visibility
                  });
                },
              )
            : null,
      ),
    );
  }
}
