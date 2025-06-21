import 'package:bikex/models/restaurant.dart';
import 'package:flutter/material.dart';

class SugResTile extends StatelessWidget {
  final Restaurant restaurant;
  const SugResTile({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: UnderlineInputBorder(
          borderSide:
              BorderSide(color: const Color.fromARGB(255, 235, 235, 235))),
      leading: Container(
        width: 60,
        height: 50,
        decoration: BoxDecoration(
          image: DecorationImage(
              image: NetworkImage(restaurant.restaurantImage),
              fit: BoxFit.cover),
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      title: Text(restaurant.restaurantName),
      subtitle: Row(
        children: [
          Icon(Icons.star, color: Colors.orange, size: 16),
          SizedBox(width: 4),
          Text(restaurant.rating.toString()),
        ],
      ),
    );
  }
}
