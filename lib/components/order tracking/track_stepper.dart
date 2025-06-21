import 'package:flutter/material.dart';

class OrderTrackingStepper extends StatelessWidget {
  final List<String> steps = [
    "Your order has been received",
    "The restaurant is preparing your food",
    "Your order has been picked up for delivery",
    "Order arriving soon!"
  ];

  final int currentStep = 1;

  OrderTrackingStepper({super.key}); // Change this value to update progress (0,1,2,3)

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.asMap().entries.map((entry) {
        int index = entry.key;
        String step = entry.value;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                // Progress Indicator
                Icon(
                  index == 0
                      ? Icons.check_circle // First step (received)
                      : index == currentStep
                          ? Icons.autorenew // Processing step
                          : Icons.check, // Completed steps
                  color: index <= currentStep ? Colors.orange : Colors.grey,
                  size: 20,
                ),
                if (index != steps.length - 1)
                  Container(
                    width: 2,
                    height: 30,
                    color: index < currentStep ? Colors.orange : Colors.grey[300],
                  ),
              ],
            ),
            SizedBox(width: 10),
            Text(
              step,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: index <= currentStep ? Colors.orange : Colors.grey,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}