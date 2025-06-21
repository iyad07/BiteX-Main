import 'package:bikex/components/mycart/cart_item_comp.dart';
import 'package:bikex/data/restaurant_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditCartPage extends StatefulWidget {
  final VoidCallback onDone;
  const EditCartPage({super.key, required this.onDone});

  @override
  State<EditCartPage> createState() => _EditCartPageState();
}

class _EditCartPageState extends State<EditCartPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantHandler>(
        builder: (context, value, child) => Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  style:
                      IconButton.styleFrom(backgroundColor: Colors.grey[200]),
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.black,
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                title: Text(
                  'Cart',
                  style: TextStyle(color: Colors.black),
                ),
                actions: [
                  TextButton(
                    onPressed: widget.onDone,
                    child: Text(
                      'DONE',
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                elevation: 0,
              ),
              body: Column(
                children: [
                  // Item list section
                  Expanded(
                    child: ListView.builder(
                      itemCount: value
                          .getCartItems()
                          .length, // Placeholder for the number of items
                      itemBuilder: (context, index) {
                        return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: CartItemComp(
                              cartItem: value.getCartItems()[index],
                              isEdit: true,
                            ));
                      },
                    ),
                  ),
                ],
              ),
            ));
  }
}
