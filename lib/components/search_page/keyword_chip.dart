import 'package:flutter/material.dart';

class KeywordChip extends StatelessWidget {
  final String label;
  const KeywordChip({super.key,required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Chip(
        label: Text(label,style: TextStyle(fontWeight: FontWeight.w400, fontSize: 16)),
        shape: StadiumBorder(side: BorderSide(color:Color.fromARGB(153, 231, 231, 231),width: 2)),
        backgroundColor: Colors.white,
      ),
    );
  }
}