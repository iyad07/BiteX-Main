import 'package:bikex/models/user.dart';

class UserProvider {
  List<RestaurantUser> users=[
    RestaurantUser(id: "", name: "Iyad", email: "", address: ["123 lab office","122 lab office"], phoneNumber: "0000123123")
  ];

  RestaurantUser demoUser() => users[0];
}