import 'package:flutter/material.dart';

Widget searchBar({bool enabled = true}) => TextField(
      enabled: enabled,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
        prefixIcon: Icon(Icons.search),
        hintText: 'Search dishes, restaurants',
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
