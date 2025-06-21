import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0,
        ),
        child: Chip(
          shadowColor: Colors.grey[200],
          elevation: 3,
          side: BorderSide(color: Colors.transparent, width: 0),
          labelPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          label: Text(label),
          shape: StadiumBorder(),
          backgroundColor: isSelected ? Colors.orange[200] : Colors.white,
          labelStyle: TextStyle(
            color: Colors.black,
          ),
          
        ),
      ),
    );
  }
}
