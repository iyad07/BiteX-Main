class RestaurantUser {
  final String id;
  final String name;
  final String email;
  late List<String> address;
  final String phoneNumber;
 

  RestaurantUser({
    required this.id,
    required this.name,
    required this.email,
    required this.address,
    required this.phoneNumber,
  });
}