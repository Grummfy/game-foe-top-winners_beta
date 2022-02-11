import 'package:flutter/material.dart';

class IconToggleButton extends StatelessWidget {
  final Function() onPressed;
  final bool isSelected;
  final Icon positive;
  final Icon negative;
  final String? tooltip;

  const IconToggleButton({
    required this.isSelected,
    required this.onPressed,
    required this.positive,
    required this.negative,
    this.tooltip
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
        icon: Padding(
            padding: EdgeInsets.zero,
            child: isSelected ? positive : negative
        ),
        tooltip: tooltip,
        onPressed: onPressed,
      );
  }
}
