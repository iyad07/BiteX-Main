import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:bikex/screens/chef_pages/chef_orders_screen.dart';


class ChefDashboard extends StatefulWidget {
  const ChefDashboard({super.key});
  

  @override
  State<ChefDashboard> createState() => _ChefDashboardState();
}

class _ChefDashboardState extends State<ChefDashboard> {
  // Helper method to build quick action buttons
  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String status,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChefOrdersScreen(initialStatus: status),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.orange.shade800, size: 24),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {},
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushNamed(context, '/chef/orders');
            },
          ),
        ],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LOCATION',
              style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
            Row(
              children: [
                Text(
                  'Halal Lab office',
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w400),
                ),
                DropdownButton(
                  icon:
                      Icon(Icons.arrow_drop_down_rounded, color: Colors.black),
                  items: [],
                  onChanged: (value) {},
                )
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
       

      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAction(
                  context,
                  icon: Icons.restaurant_menu,
                  label: 'New Orders',
                  status: 'pending',
                ),
                _buildQuickAction(
                  context,
                  icon: Icons.timer,
                  label: 'Preparing',
                  status: 'preparing',
                ),
                _buildQuickAction(
                  context,
                  icon: Icons.done_all,
                  label: 'Ready',
                  status: 'ready',
                ),
              ],
            ),
            SizedBox(height: 20),
            SizedBox(height: 12),

            // Statistics Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatisticCard(
                  title: 'RUNNING ORDERS',
                  value: '20',
                ),
                StatisticCard(
                  title: 'ORDER REQUEST',
                  value: '05',
                ),
              ],
            ),
            SizedBox(height: 24),

            // Total Revenue Section
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              elevation: 0, // Remove shadow by setting elevation to 0
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Revenue',
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        Text(
                          '\$2,241',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            DropdownButton<String>(
                              value: 'Daily',
                              items: [
                                DropdownMenuItem(
                                    value: 'Daily',
                                    child: Text('Daily')),
                                DropdownMenuItem(
                                    value: 'Weekly',
                                    child: Text('Weekly')),
                                DropdownMenuItem(
                                    value: 'Monthly',
                                    child: Text('Monthly')),
                              ],
                              onChanged: (value) {},
                            ),
                            Text(
                              'See Details',
                              style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 80,
                      child: LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                FlSpot(0, 300),
                                FlSpot(1, 400),
                                FlSpot(2, 500),
                                FlSpot(3, 600),
                                FlSpot(4, 700),
                                FlSpot(5, 800),
                                FlSpot(6, 900),
                              ],
                              isCurved: true,
                              color: Colors.orange,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.orange[300],
                              ),
                            ),
                          ],
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 22,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  switch (value.toInt()) {
                                    case 0:
                                      return Text('10AM');
                                    case 1:
                                      return Text('11AM');
                                    case 2:
                                      return Text('12PM');
                                    case 3:
                                      return Text('01PM');
                                    case 4:
                                      return Text('02PM');
                                    case 5:
                                      return Text('03PM');
                                    case 6:
                                      return Text('04PM');
                                    default:
                                      return Text('');
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Reviews Section
            Card(
              elevation: 0,
              color: Colors.white, // No shadow
              margin: EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reviews',
                          style:
                              TextStyle(fontSize: 16,),
                        ),
                        Text(
                          'See All Reviews',
                          style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.orange, size: 24),
                        SizedBox(width: 8),
                        Text(
                          '4.9',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Total 20 Reviews',
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Popular Items Section
            Card(
              elevation: 0,
              color: Colors.white, // No shadow
              margin: EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Popular Items This Week',
                          style: TextStyle(fontSize: 16,),
                        ),
                        Text(
                          'See All',
                          style: TextStyle(
                              color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        spacing: 24,
                        children: [
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 0,
        notchMargin: 6,
        shape: CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.grid_view, color: Colors.orange),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.menu, color: Colors.orange),
              onPressed: () {},
            ),
            FloatingActionButton(
              onPressed: () {},
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange,
              shape: CircleBorder(side: BorderSide(color: Colors.orange)),
              elevation: 0,
              child: Icon(Icons.add),
            ),
            IconButton(
              icon: Icon(Icons.notifications, color: Colors.orange),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.person, color: Colors.orange),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}



// Statistic Card Widget
class StatisticCard extends StatelessWidget {
  final String title;
  final String value;

  const StatisticCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 185,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 52, fontWeight: FontWeight.bold),
          ),
          //SizedBox(height: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
