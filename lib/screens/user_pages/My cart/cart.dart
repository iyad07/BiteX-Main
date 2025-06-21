import 'package:bikex/components/buttons.dart';
import 'package:bikex/components/mycart/cart_item_comp.dart';
import 'package:bikex/models/cart_item.dart';
import 'package:bikex/data/restaurant_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CartPage extends StatelessWidget {
  final VoidCallback onEdit;
  const CartPage({super.key, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantHandler>(
      builder: (context, restaurantHandler, child) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: backButton(context),
          title: const Text(
            'Cart',
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            editButton(onEdit)
          ],
          elevation: 0,
        ),
        body: Consumer<RestaurantHandler>(
          builder: (context, restaurantHandler, child) {
            final cartItems = restaurantHandler.getCartItems();
            List<CartItem> filteredCartItems = cartItems
                .where((cartItem) => cartItem.quantity > 0)
                .toList();
            return Column(
              children: [
                filteredCartItems.isEmpty
                    ? Expanded(
                        child: Center(
                            child: Text(
                          "Your cart is empty.",
                          style: TextStyle(fontSize: 18),
                        )),
                      )
                    : Expanded(
                        child: ListView.builder(
                          itemCount: filteredCartItems.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: CartItemComp(
                                cartItem: filteredCartItems[index],
                                isEdit: false,
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
             
