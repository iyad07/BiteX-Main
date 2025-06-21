import 'package:bikex/components/buttons.dart';
import 'package:bikex/models/order.dart';
import 'package:flutter/material.dart';

class OrderItemComponent extends StatefulWidget {
  final OrderModel order;
  final bool isOngoing;
  final bool isCompleted;
  final bool isCancelled;
  
  const OrderItemComponent({super.key, required this.order, this.isOngoing=true,this.isCancelled=false,this.isCompleted=false});

  @override
  State<OrderItemComponent> createState() => _OrderItemComponentState();
}

class _OrderItemComponentState extends State<OrderItemComponent> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text("Food"),
        ),
        ListTile(
          isThreeLine: true,
          leading: Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          trailing: Text(widget.order.id, style: TextStyle(decoration: TextDecoration.underline)),
          title: Text('Pizza Hut'),
          subtitle: Text('838.25 | 0 Items'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: widget.isCompleted || widget.isCancelled ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width:170, child: smoutLinedButton('Rate', (){},false)),
              SizedBox(width: 170,child: smelevatedButton('Re-order', (){})),
            ],
          ):Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width:170, child: smelevatedButton('Track Order', (){})),
              SizedBox(width: 170,child: smoutLinedButton('Cancel', (){},false)),
            ],
          ),
        ),
      ],
    );
  }
}