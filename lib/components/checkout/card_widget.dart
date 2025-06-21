import 'package:flutter/material.dart';

class CardWidget extends StatelessWidget {
  const CardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent, // Make the Material background transparent
        child: InkWell(
          borderRadius: BorderRadius.circular(16), // Rounded borders for splash effect
          splashColor: Colors.grey[200], // Splash color for tap feedback
          onTap: () {
            // Handle tap event here
          },
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
              ),
              child: Center(
                child: Icon(Icons.credit_card,
                    color: Colors.orange), // Replace with an actual logo if needed
              ),
            ),
            title: Text(
              'Master Card',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              Icons.arrow_drop_down,
              color: Colors.grey,
            ),
            // Dropdown arrow
            subtitle: Text(
              '436',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
