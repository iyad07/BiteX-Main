import 'package:bikex/components/restaurant_page/category_chip.dart';
//import 'package:bikex/components/restaurant_page/filter_popup.dart';
import 'package:bikex/components/restaurant_page/food_tile.dart';
import 'package:bikex/data/restaurant_handler.dart';
import 'package:bikex/models/restaurant.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RestaurantPage extends StatefulWidget {
  final Restaurant? restaurant;
  const RestaurantPage({
    super.key,
    this.restaurant,
  });

  @override
  State<RestaurantPage> createState() => _RestaurantPageState();
}

class _RestaurantPageState extends State<RestaurantPage> {
  late RestaurantHandler restaurantHandler;
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.restaurant == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(child: Text('Restaurant data not found')),
      );
    }
    
    return Consumer<RestaurantHandler>(
      builder: (context, value, child) {
        return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            "Restaurant View",
            style: TextStyle(fontSize: 17),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
            ),
            style: IconButton.styleFrom(backgroundColor: Colors.grey[100]),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
                    actions: [
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/my_cart');
              },
              child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    margin: EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          value.cartItems.length.toString(),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant Image
              Container(
                width: double.infinity,
                height: 150,
                clipBehavior: Clip.none,
                decoration: BoxDecoration(
                  image: DecorationImage(
                      image: NetworkImage(widget.restaurant!.restaurantImage),
                      fit: BoxFit.cover),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 16),

              // Restaurant Details
              Text(
                widget.restaurant!.restaurantName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Maecenas sed diam eget risus varius blandit sit amet non magna. Integer posuere erat a ante venenatis dapibus posuere velit aliquet.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Ratings and Info
              Row(
                children: [
                  Row(
                    children: const [
                      Icon(Icons.star, color: Colors.orange, size: 20),
                      SizedBox(width: 4),
                      Text("4.7",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: const [
                      Icon(Icons.local_shipping,
                          color: Colors.orange, size: 20),
                      SizedBox(width: 4),
                      Text("Free"),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: const [
                      Icon(Icons.access_time, color: Colors.orange, size: 20),
                      SizedBox(width: 4),
                      Text("20 min"),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Track Order Button (Demo)
              if (widget.restaurant!.hasLocation)
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Demo order tracking with sample data
                      Navigator.pushNamed(
                        context,
                        '/order_tracking',
                        arguments: {
                          'restaurant': widget.restaurant!,
                          'orderItems': widget.restaurant!.foodList.take(2).toList(),
                          'orderNumber': '#BX${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                          'customerLocation': null, // Will use current location
                        },
                      );
                    },
                    icon: const Icon(Icons.location_on, color: Colors.white),
                    label: const Text(
                      'Track Sample Order',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Food Categories
              Row(
                children: [
                  buildCategoryChip("Rice", true),
                  const SizedBox(width: 8),
                  buildCategoryChip("Salad", false),
                  const SizedBox(width: 8),
                  buildCategoryChip("Beverages", false),
                  const SizedBox(width: 8),
                  buildCategoryChip("Extras", false),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Rice (10)",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 16),
              // Food Grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 4.2 / 4,
                  ),
                  itemCount: widget.restaurant!.foodList.length,
                  itemBuilder: (context, index) {
                    return FoodTile(
                      food: widget.restaurant!.foodList[index],
                        restaurant: widget.restaurant!,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/food_page',
                        arguments: widget.restaurant!.foodList[index],
                      ),
                      onaddTap: () {
                        Provider.of<RestaurantHandler>(context, listen: false)
                            .addToCart(widget.restaurant!.foodList[index]);
                        if (Provider.of<RestaurantHandler>(context,
                                listen: false)
                            .isAlreadyInCart) {
                          _showSnackBar(context, "Item already in cart");
                        } else {
                          _showSnackBar(context, "Added to cart");
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
