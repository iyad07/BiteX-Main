import 'package:bikex/components/food_page/ingred_icon.dart';
import 'package:bikex/data/restaurant_handler.dart';
import 'package:bikex/models/food.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class FoodPages extends StatefulWidget {
  final Food? food;
  const FoodPages({super.key, this.food});

  @override
  State<FoodPages> createState() => _FoodPagesState();
}

class _FoodPagesState extends State<FoodPages> { 
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
    if (widget.food == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(child: Text('Food data not found')),
      );
    }
    
    return Consumer<RestaurantHandler>(
      builder: (context, value, child) {
        return Scaffold(
          bottomSheet: Padding(
            padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "\$${widget.food!.price}",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                /*Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () {},
                    ),
                    Text(
                      "2",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {},
                    ),
                  ],
                ),*/
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Provider.of<RestaurantHandler>(context, listen: false)
                    .addToCart(widget.food!);
                                if (Provider.of<RestaurantHandler>(context, listen: false)
                      .isAlreadyInCart) {
                    _showSnackBar(context, "Item already in cart");
                  } else {
                    _showSnackBar(context, "Added to cart");
                  }

              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Center(
                child: Text(
                  "ADD TO CART",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Food Details",
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
              alignment: Alignment.bottomRight,
              width: double.infinity,
              height: 184,
              clipBehavior: Clip.none,
              decoration: BoxDecoration(
                image: DecorationImage(
                    image: NetworkImage(widget.food!.foodImage!),
                    fit: BoxFit.fitWidth),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[400],
                    foregroundColor: Colors.white),
                onPressed: () {},
                icon: Icon(
                  Icons.favorite_outline,
                ),
              ),
            ),
            const SizedBox(height: 16),
            //Restaurant name
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  widget.food!.restaurant?.restaurantName ??
                      "Unknown Restaurant",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
    
            // food Details
            Text(
              widget.food!.foodTitle,
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
                    Text("4.7", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: const [
                    Icon(Icons.local_shipping, color: Colors.orange, size: 20),
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
            SizedBox(height: 16),
            // Ingredients
            Text(
              "INGREDIENTS",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildIngredientIcon(Icons.local_pizza),
                buildIngredientIcon(Icons.no_meals),
                buildIngredientIcon(Icons.dining),
                buildIngredientIcon(Icons.food_bank),
                buildIngredientIcon(Icons.set_meal),
              ],
            ),
            Spacer(),
            // Price and Add to Cart
          ],
        ),
      ),
    );
    });  
}
}
