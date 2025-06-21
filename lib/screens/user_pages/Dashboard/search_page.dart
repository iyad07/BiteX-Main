import 'package:bikex/components/dashboard/search_bar.dart';

// import 'package:bikex/components/search_page/keyword_chip.dart';
import 'package:bikex/components/search_page/pop_food_tile.dart';
import 'package:bikex/components/search_page/sug_res__tile.dart';

import 'package:bikex/data/restaurant_handler.dart';
import 'package:flutter/material.dart';
import 'package:bikex/models/food.dart';
import 'package:bikex/models/restaurant.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late List<dynamic> searchResults = [];
  //final List<dynamic> _searchResults = [];
  String _searchQuery = '';
  late List<Restaurant> restaurantList;
  late List<Food> foodList;

  //method to filter restaurant and food list
  List<dynamic> _filterSearchResults(String query) {
    final List<Restaurant> filteredRestaurants = restaurantList
        .where((restaurant) {
            if (query.isEmpty) return false;
            return restaurant.restaurantName.toLowerCase().startsWith(query.toLowerCase());
          }
        )
        .toList();

    final List<Food> filteredFoods = foodList
        .where((food) {
            if (query.isEmpty) return false;
            return food.foodTitle.toLowerCase().startsWith(query.toLowerCase());
          }
        )
        .toList();

    return [...filteredRestaurants, ...filteredFoods];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantHandler>(builder: (context, value, child) {
      //get restaurants and foods from provider
      restaurantList = value.restaurants;
      foodList = value.getAllFood();

      // Method for on search query change
      void onSearchQueryChange(String query) {
        setState(() {
          _searchQuery = query;
          searchResults = _filterSearchResults(_searchQuery);
        });
      }

      //verify if there are results to show
      final hasResults = _searchQuery.isNotEmpty && searchResults.isNotEmpty;
      //verify if there are no results
      final noResults = _searchQuery.isNotEmpty && searchResults.isEmpty;

      //build the ui
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            margin: EdgeInsets.all(8),
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: Colors.grey[200]),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.black,
                size: 15,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          title: Text(
            'Search',
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/my_cart');
              },
              child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    margin: EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '2',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                SearchBarField(
                  onSearchChanged: onSearchQueryChange,
                  query: _searchQuery,
                ),

                const SizedBox(height: 20),

                // Recent Keywords
                /*Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'Recent Keywords',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 20,
                    ),
                  ),
                ),
                SizedBox(
                  height: 70,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      KeywordChip(label: 'Burger'),
                      KeywordChip(label: 'Sandwich'),
                      KeywordChip(label: 'Pizza'),
                      KeywordChip(label: 'Sandwich'),
                    ],
                  ),
                ),*/
                if (!hasResults && !noResults) ...[
                  const SizedBox(height: 20),
                  // Suggested Restaurants
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: const Text(
                      'Suggested Restaurants',
                      style:
                          TextStyle(fontWeight: FontWeight.w400, fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 264,
                    child: ListView(
                      children: [
                        SugResTile(restaurant: restaurantList[0]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Popular Fast Food
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: const Text(
                      'Popular Fast Food',
                      style:
                          TextStyle(fontWeight: FontWeight.w400, fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      mainAxisExtent: 144,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      //mainAxisStartPadding: 0,
                    ),
                    itemCount:
                        foodList.length, // Adjust this based on your data
                    itemBuilder: (context, index) {
                      return PopFoodTile(
                        food: foodList[index],
                        restaurant: foodList[index]
                            .restaurant!, 
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/food_page',
                              arguments: foodList[index],
                            ),// Assuming Restaurant() is a valid default value
                      );
                    },
                  ),
                ] else if (noResults) ...[
                  // No results found message
                  const SizedBox(height: 20),
                  const Center(
                    child: Text('No results found.'),
                  ),
                ] else if (hasResults) ...[
                  // Show search results
                  for (final item in searchResults) ...[
                    const SizedBox(height: 20),
                    if (item is Restaurant) SugResTile(restaurant: item),
                    if (item is Food)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          PopFoodTile(food: item, restaurant: item.restaurant!,onTap: () => Navigator.pushNamed(
                              context,
                              '/food_page',
                              arguments: item,
                            ),),
                        ],
                      ),
                  ],
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}
