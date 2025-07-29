import 'package:flutter/material.dart';

class MyDropdown extends StatefulWidget {
  final List<String> items;
  final String? initialValue;
  final void Function(String?) onChanged;
  final IconData? icon;
  final String? hint;

  const MyDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.initialValue,
    this.icon,
    this.hint,
  });

  @override
  State<MyDropdown> createState() => _MyDropdownState();
}

class _MyDropdownState extends State<MyDropdown> {
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    // Initialize with a valid value
    selectedValue =
        widget.items.contains(widget.initialValue) ? widget.initialValue : null;
  }

  @override
  void didUpdateWidget(covariant MyDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update selectedValue when items or initialValue changes
    if (widget.initialValue != oldWidget.initialValue ||
        widget.items != oldWidget.items) {
      setState(() {
        selectedValue = widget.items.contains(widget.initialValue)
            ? widget.initialValue
            : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          hint: widget.hint != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 5.0),
                  child: Text(
                    widget.hint!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary),
                  ),
                )
              : null,
          icon: Icon(
            widget.icon,
            color: Theme.of(context).colorScheme.tertiary,
            size: 20,
          ),
          dropdownColor: Colors.black87,
          style: TextStyle(
            color: Theme.of(context).colorScheme.inverseSurface,
            fontSize: 15,
          ),
          onChanged: (value) {
            setState(() {
              selectedValue = selectedValue == value ? null : value;
            });
            widget.onChanged(selectedValue);
          },
          items: widget.items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ),
    );
  }
}
