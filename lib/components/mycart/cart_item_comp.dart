import 'package:bikex/models/cart_item.dart';
import 'package:bikex/data/restaurant_handler.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CartItemComp extends StatefulWidget {
  final CartItem cartItem;
  final bool isEdit;

  const CartItemComp({super.key, required this.cartItem, required this.isEdit});

  @override
  State<CartItemComp> createState() => _CartItemState();
}

class _CartItemState extends State<CartItemComp> {
  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantHandler>(builder: (context, handler, child) {
      return Row(
        children: [
          Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateX(-0.3), // tilt backwards (negative angle)
            alignment: Alignment.center,
            child: Container(
              width: 136,
              height: 117,
              alignment: Alignment.bottomCenter,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: NetworkImage(widget.cartItem.food.foodImage!),
                ),
                color: Colors.grey,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[200]!,
                    blurRadius: 30,
                    offset: Offset(12, 12),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //Food Name
                Text(
                  widget.cartItem.food.foodTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                ),
                SizedBox(height: 8),
                //price
                Text(
                  "\$${widget.cartItem.food.price * widget.cartItem.quantity}",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                Text(
                  "(\$${widget.cartItem.food.price} each)",
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              widget.isEdit
                  ?
                  //delete button
                  SizedBox(
                      height: 27,
                      width: 27,
                      child: IconButton(
                        iconSize: 12,
                        onPressed: () {
                          Provider.of<RestaurantHandler>(context, listen: false)
                              .removeFromCart(
                            widget.cartItem.food,
                          );
                        },
                        icon: Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    )
                  : SizedBox(),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Provider.of<RestaurantHandler>(context, listen: false)
                          .decreaseQuantity(widget.cartItem.food);
                    },
                    icon: Icon(
                      Icons.remove,
                    ),
                  ),
                  Text(widget.cartItem.quantity.toString()),
                  IconButton(
                    onPressed: () {
                      Provider.of<RestaurantHandler>(context, listen: false)
                          .increaseQuantity(widget.cartItem.food);
                    },
                    icon: Icon(
                      Icons.add,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    });
  }
}
