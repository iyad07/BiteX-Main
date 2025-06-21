import 'package:bikex/data/restaurant_handler.dart';
import 'package:bikex/data/user_provider.dart'; // Add import for UserProvider
import 'package:bikex/components/buttons.dart';
//import 'package:bikex/components/cred_textfields.dart';
import 'package:bikex/screens/user_pages/My%20cart/cart.dart';
import 'package:bikex/screens/user_pages/My%20cart/edit_cart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyCart extends StatefulWidget {
  const MyCart({
    super.key,
  });

  @override
  State<MyCart> createState() => _MyCartState();
}

class _MyCartState extends State<MyCart> {
  bool isEditMode = false;
  int selectedAddressIndex = 0; // To track which address is selected

  void toggleEditMode() {
    setState(() {
      isEditMode = !isEditMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Create an instance of UserProvider to access user data
    final userProvider = UserProvider();
    final user = userProvider.demoUser();
    
    return Consumer<RestaurantHandler>(
      builder: (context, value, child) => Scaffold(
        bottomSheet: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DELIVERY ADDRESS',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  textButton("CHANGE", () {
                    // Show address selection dialog
                    _showAddressSelectionDialog(context, user.address);
                  })
                ],
              ),
              SizedBox(height: 8),
              // Display the selected address instead of the text field
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                width: double.infinity,
                child: Text(
                  user.address.isNotEmpty 
                      ? user.address[selectedAddressIndex] 
                      : "No address available",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'TOTAL:  ',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w400),
                      ),
                      Text(
                        '\$${value.getTotal().toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              elevatedButton("PLACE ORDER", () {
                Navigator.pushNamed(context, '/check_out');
              }),
            ],
          ),
        ),
        body: isEditMode
            ? EditCartPage(onDone: toggleEditMode)
            : CartPage(
                onEdit: toggleEditMode,
              ),
      ),
    );
  }
  
  // Method to show address selection dialog
  void _showAddressSelectionDialog(BuildContext context, List<String> addresses) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Delivery Address"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(addresses[index]),
                  leading: Radio<int>(
                    value: index,
                    groupValue: selectedAddressIndex,
                    onChanged: (value) {
                      setState(() {
                        selectedAddressIndex = value!;
                        Navigator.pop(context);
                      });
                    },
                  ),
                  onTap: () {
                    setState(() {
                      selectedAddressIndex = index;
                      Navigator.pop(context);
                    });
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}