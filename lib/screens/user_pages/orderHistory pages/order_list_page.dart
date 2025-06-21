import 'package:bikex/components/buttons.dart';
import 'package:bikex/screens/user_pages/orderHistory%20pages/ongoing_orders.dart';
import 'package:bikex/screens/user_pages/orderHistory%20pages/order_history.dart';
import 'package:flutter/material.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: backButton(context),
          title: Text('My Orders'),
          bottom: TabBar(
            indicatorColor: Colors.orange,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.orange,
            tabs: [
              Tab(text: 'Ongoing'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            OngoingOrders(),
            HistoryOrders(),
          ],
        ),
      ),
    );
  }
}
