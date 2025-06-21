import 'package:flutter/material.dart';

Widget profilePageGroup(List<Map<String, dynamic>> groupItems) {
  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 16.0,
    ),
    child: Stack(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListView.builder(
          itemCount: groupItems.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(groupItems[index]['title']),
              leading: Icon(groupItems[index]['icon']),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
              ),
              tileColor: Colors.white,
              hoverColor: Colors.grey[300],
              selectedTileColor: Colors.blue[100],
              onTap: 
                groupItems[index]['onTap']
            );
          },
        ),
        ),
      ],
    ),
  );
}

Widget persnalprofileGroup(List<Map<String, dynamic>> groupItems) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Container(
      height: 250,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: groupItems.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(groupItems[index]['title']),
            subtitle: Text(groupItems[index]['subtitle']),
            leading: Icon(groupItems[index]['icon']),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
            ),
            tileColor: Colors.white,
            hoverColor: Colors.grey[300],
            selectedTileColor: Colors.blue[100],
            onTap: () {
              // Handle tap
              
            },
          );
        },
      ),
    ),
  );
}
