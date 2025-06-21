import 'package:flutter/material.dart';

Widget buildCategoryChip(String label, bool isSelected) {
  return Container(
    height: 46,
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      border: isSelected
          ? Border.all(width: 1, color: Colors.orange)
          : Border.all(width: 1, color: Colors.grey[300]!),
      color: isSelected ? Colors.orange : Colors.white,
      borderRadius: BorderRadius.circular(33),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    ),
  );
}
