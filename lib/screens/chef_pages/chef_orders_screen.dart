import 'package:bikex/models/cart_item.dart';
import 'package:bikex/models/order.dart';
import 'package:bikex/data/restaurant_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChefOrdersScreen extends StatefulWidget {
  final String? initialStatus;

  const ChefOrdersScreen({
    Key? key,
    this.initialStatus,
  }) : super(key: key);

  @override
  _ChefOrdersScreenState createState() => _ChefOrdersScreenState();
}

class _ChefOrdersScreenState extends State<ChefOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _getInitialTabIndex(),
    );
  }

  int _getInitialTabIndex() {
    switch (widget.initialStatus?.toLowerCase()) {
      case 'preparing':
        return 1;
      case 'ready':
        return 2;
      case 'pending':
      default:
        return 0;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Orders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.orange,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.access_time),
              text: 'New Orders',
            ),
            Tab(
              icon: Icon(Icons.restaurant),
              text: 'Preparing',
            ),
            Tab(
              icon: Icon(Icons.done_all),
              text: 'Ready',
            ),
          ],
        ),
      ),
      body: Consumer<RestaurantHandler>(
        builder: (context, handler, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              // New Orders Tab
              _buildOrderList(
                orders: handler.pendingOrders.cast<OrderModel>(),
                status: OrderStatus.pending,
                emptyMessage: 'No new orders',
              ),
              // Preparing Orders Tab
              _buildOrderList(
                orders: handler.preparingOrders.cast<OrderModel>(),
                status: OrderStatus.preparing,
                emptyMessage: 'No orders in progress',
              ),
              // Ready Orders Tab
              _buildOrderList(
                orders: handler.readyOrders.cast<OrderModel>(),
                status: OrderStatus.ready,
                emptyMessage: 'No orders ready for pickup',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderList({
    required List<OrderModel> orders,
    required OrderStatus status,
    required String emptyMessage,
  }) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order, status);
      },
    );
  }

  Widget _buildOrderCard(OrderModel order, OrderStatus currentStatus) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: currentStatus == OrderStatus.pending
                ? Colors.orange
                : currentStatus == OrderStatus.preparing
                    ? Colors.blue
                    : Colors.green.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
currentStatus == OrderStatus.pending
    ? Icons.access_time
    : currentStatus == OrderStatus.preparing
        ? Icons.restaurant
        : Icons.done_all,
            color: currentStatus == OrderStatus.pending 
                ? Colors.orange
                : currentStatus == OrderStatus.preparing
                    ? Colors.blue 
                    : Colors.green,
            size: 24.0,
          ),
        ),
        title: Text(
          'Order #${order.id.substring(0, 8)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4.0),
            Text(
              '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'} • ${order.formattedOrderTime}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13.0,
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                Text(
                  '\$${order.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            if (order.notes?.isNotEmpty ?? false)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                margin: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.orange[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Note:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE65100),
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      order.notes!,
                      style: TextStyle(
                        color: Colors.orange[800],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        children: [
          Divider(height: 1.0, color: Colors.grey[300]),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Items:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  'Customer: ${order.customerName}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Items:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...order.items.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color:
                          item.isPrepared ? Colors.green[50] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: item.isPrepared
                            ? Colors.green[100]!
                            : Colors.grey[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: item.isPrepared,
                          onChanged: (bool? value) {
                            if (value != null) {
                              _updateItemStatus(order, item, value);
                            }
                          },
                          activeColor: Colors.green,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.food.foodTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  decoration: item.isPrepared
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: item.isPrepared
                                      ? Colors.grey[600]
                                      : Colors.black,
                                ),
                              ),
                              if (item.notes?.isNotEmpty ?? false)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    'Note: ${item.notes}',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      color: Colors.orange[700],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '×${item.quantity}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14.0,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          '\$${(item.food.price * item.quantity).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    if (currentStatus == OrderStatus.pending)
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.restaurant_menu, size: 20.0),
                          label: const Text('Start Preparing'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          onPressed: () =>
                              _updateOrderStatus(order, OrderStatus.preparing),
                        ),
                      )
                    else if (currentStatus == OrderStatus.preparing)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: order.items
                                  .every((item) => item.isPrepared)
                              ? () =>
                                  _updateOrderStatus(order, OrderStatus.ready)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.done_all, size: 20.0),
                              SizedBox(width: 8.0),
                              Text('Mark as Ready'),
                            ],
                          ),
                        ),
                      ),
                    if (currentStatus == OrderStatus.preparing &&
                        !order.items.every((item) => item.isPrepared))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Please mark all items as prepared before completing the order',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12.0,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _updateItemStatus(OrderModel order, CartItem item, bool isPrepared) async {
    try {
      final handler = Provider.of<RestaurantHandler>(context, listen: false);
      final updatedItems = order.items.map((i) {
        if (i.id == item.id) {
          return i.copyWith(isPrepared: isPrepared);
        }
        return i;
      }).toList();

      final updatedOrder = order.copyWith(items: updatedItems);

      // Update in Firestore
      await handler.updateOrder(updatedOrder);

      // Show a snackbar for better user feedback
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${item.food.foodTitle} marked as ${isPrepared ? 'prepared' : 'not prepared'}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update item status: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
    }
  }

  void _updateOrderStatus(OrderModel order, OrderStatus newStatus) async {
    try {
      final handler = Provider.of<RestaurantHandler>(context, listen: false);

      // Update in Firestore
      await handler.updateOrderStatus(order.id, newStatus);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Order marked as ${newStatus.toString().split('.').last}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
    }
  }
}
