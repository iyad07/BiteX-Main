import 'package:bikex/components/order_history/order_item_component.dart';
import 'package:bikex/data/restaurant_handler.dart';
import 'package:bikex/models/order.dart';
import 'package:flutter/material.dart';

class OngoingOrders extends StatefulWidget {
  const OngoingOrders({super.key});

  @override
  State<OngoingOrders> createState() => _OngoingOrdersState();
}

class _OngoingOrdersState extends State<OngoingOrders> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        OrderItemComponent(
          order: OrderModel(
              customerPhone: "1234567890",
              customerName: "Customer",
              id: "#2000",
              items: [],
              totalPrice: 40,
              deliveryAddress: "",
              restaurant: RestaurantHandler().restaurants[0]),
        ),
      ],
    );
  }
}
