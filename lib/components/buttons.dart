//import 'package:bikex/data/restaurant_handler.dart';
import 'package:flutter/material.dart';
//import 'package:provider/provider.dart';

TextButton textButton(String label, VoidCallback onClick) => TextButton(
      onPressed: onClick,
      child: Text(
        label,
        style: TextStyle(color: Colors.orange),
      ),
    );

ElevatedButton elevatedButton(
  String label,
  VoidCallback onClick,
) =>
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.symmetric(vertical: 24),
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: onClick,
      child: Text(
        label,
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
ElevatedButton smelevatedButton(
  String label,
  VoidCallback onClick,
) =>
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.symmetric(vertical: 15),
      ),
      onPressed: onClick,
      child: Text(
        label,
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
ElevatedButton outLinedButton(String label, VoidCallback onClick) =>
    ElevatedButton.icon(
      style: OutlinedButton.styleFrom(
        shadowColor: Colors.transparent,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: Colors.grey[200]!,
            width: 2,
          ), // Changed border color to orange
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: onClick,
      icon: Icon(
        Icons.add,
        color: Colors.orange,
      ),
      label: Text(
        label,
        style: TextStyle(color: Colors.orange, fontSize: 16),
      ),
    );
ElevatedButton smoutLinedButton(
        String label, VoidCallback onClick, bool hasIcon) =>
    ElevatedButton.icon(
      style: OutlinedButton.styleFrom(
        shadowColor: Colors.transparent,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: Colors.grey[200]!,
            width: 2,
          ), // Changed border color to orange
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
      onPressed: onClick,
      icon: hasIcon
          ? Icon(
              Icons.add,
              color: Colors.orange,
            )
          : null,
      label: Text(
        label,
        style: TextStyle(color: Colors.orange, fontSize: 16),
      ),
    );

TextButton textButtonIcon(label, onClick, Icon icon) => TextButton.icon(
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 0),
      ),
      onPressed: onClick,
      iconAlignment: IconAlignment.end,
      label: Text(
        label,
        style: TextStyle(
            color: Colors.black, fontSize: 16, fontWeight: FontWeight.normal),
      ),
      icon: icon,
    );

backButton(context) {
  return Container(
    margin: EdgeInsets.all(8),
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[200]),
    child: IconButton(
      icon: Icon(
        Icons.arrow_back_ios_rounded,
        color: Colors.black,
        size: 15,
      ),
      onPressed: () {
        Navigator.of(context).pop();
      },
    ),
  );
}

menuButton(context) {
  return Container(
    margin: EdgeInsets.all(8),
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[200]),
    child: IconButton(
      icon: Icon(
        Icons.menu_rounded,
        color: Colors.black,
        size: 15,
      ),
      onPressed: () {
        Navigator.pushNamed(context, '/profile');
      },
    ),
  );
}

TextButton editButton(onEdit) {
  return TextButton(
    onPressed: onEdit,
    child: Text(
      'EDIT ITEMS',
      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
    ),
  );
}



