import 'package:bikex/components/restaurant_page/category_chip.dart';
import 'package:flutter/material.dart';

class FilterFood extends StatelessWidget {
  const FilterFood({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Filter your search",
            style: TextStyle(fontSize: 17),
          ),
          IconButton(
            onPressed: () {Navigator.pop(context);},
            icon: Icon(Icons.close_rounded),
            style: IconButton.styleFrom(backgroundColor: Colors.grey[100]),
          )
        ],
      ),
      content: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            buildCategoryChip("Delivery", false),
            buildCategoryChip("Delivery", false),
            buildCategoryChip("Delivery", false),
            buildCategoryChip("Delivery", false),
          ],
        ),
      ),
    );
  }
}
