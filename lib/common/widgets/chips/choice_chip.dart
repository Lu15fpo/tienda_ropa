import 'package:flutter/material.dart';
import 'package:tienda_ropa/common/widgets/custom_shapes/containers/circular_container.dart';
import 'package:tienda_ropa/utils/helpers/helper_functions.dart';

import '../../../utils/constants/colors.dart';

class TChoiceChip extends StatelessWidget {
  const TChoiceChip({
    super.key,
    required this.text,
    required this.selected,
    this.onSelected,
  });

  final String text;
  final bool selected;
  final void Function(bool)? onSelected;

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Use a transparent canvas color to match the existing styling.
      data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
      child: ChoiceChip(
        // Use this function to get Colors as a Chip
        avatar: THelperFunctions.getColor(text) != null
            ? TCircularContainer(width: 50, height: 50, backgroundColor: THelperFunctions.getColor(text)!)
            : null,
        selected: selected,
        onSelected: onSelected,
        backgroundColor: THelperFunctions.getColor(text),
        labelStyle: TextStyle(color: selected ? TColors.white : null),
        shape: THelperFunctions.getColor(text) != null ? const CircleBorder() : null,
        label: THelperFunctions.getColor(text) == null ? Text(text) : const SizedBox(),
        padding: THelperFunctions.getColor(text) != null ? const EdgeInsets.all(0) : null,
        labelPadding: THelperFunctions.getColor(text) != null ? const EdgeInsets.all(0) : null,
      ),
    );
  }
}