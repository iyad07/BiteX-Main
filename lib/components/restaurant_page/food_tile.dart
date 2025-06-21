import 'package:bikex/models/food.dart';
import 'package:bikex/models/restaurant.dart';
import 'package:flutter/material.dart';

class FoodTile extends StatelessWidget {
  final Food food;
  final Restaurant restaurant;
  final Function onTap;
  final Function onaddTap;
  const FoodTile(
      {super.key,
      required this.food,
      required this.restaurant,
      required this.onTap,
      required this.onaddTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(), // Fix applied here
      child: SizedBox(
        height: 144,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // perspective
                  ..rotateX(-0.3), // tilt backwards (negative angle)
                alignment: Alignment.center,
                child: Container(
                  width: 154,
                  height: 130,
                  alignment: Alignment.bottomCenter,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey[200]!,
                        blurRadius: 30,
                        offset: Offset(12, 12),
                      ),
                    ],
                  ),
                  child: Transform(
                    transform: Matrix4.identity()..rotateX(0.2),
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            food.foodTitle,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            restaurant.restaurantName,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("\$${food.price}"),
                              SizedBox(
                                height: 30,
                                width: 30,
                                child: IconButton(
                                  onPressed: () => onaddTap(),
                                  style: IconButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.orange,
                                  ),
                                  icon: Icon(Icons.add, size: 15),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: 84,
                width: 122,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  image: DecorationImage(
                      image: NetworkImage(food.foodImage!), fit: BoxFit.cover),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
