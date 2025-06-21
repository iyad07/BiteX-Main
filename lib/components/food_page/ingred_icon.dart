import 'package:flutter/material.dart';

Widget buildIngredientIcon(IconData icon) {
    return CircleAvatar(
      backgroundColor: Colors.orange[100],
      child: Icon(
        icon,
        color: Colors.orange,
      ),
    );
  }