import 'package:bikex/components/buttons.dart';
import 'package:flutter/material.dart';
import '../../../models/order.dart';

class PaymentSuccessPage extends StatelessWidget {
  final OrderModel? order;
  const PaymentSuccessPage({super.key, this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: backButton(context),),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Congratulations!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'You successfully made a payment.',
                    style: TextStyle(fontSize: 18),
                  ),
                  //SizedBox(height: 30),
                ],
              ),
            ),
            Expanded(child: Center(child: elevatedButton("TRACK ORDER", () {
              Navigator.pushNamed(context, '/map', arguments: order);
            })))
          ],
        ),
      ),
    );
  }
}
