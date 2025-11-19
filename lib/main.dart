import 'package:bikex/data/restaurant_handler.dart';
import 'package:bikex/models/food.dart';
import 'package:bikex/models/order.dart';
import 'package:bikex/models/restaurant.dart';
import 'package:bikex/screens/chef_pages/dashboard_screen.dart';
import 'package:bikex/screens/user_pages/Dashboard/dashboard.dart';
import 'package:bikex/screens/user_pages/Dashboard/search_page.dart';
import 'package:bikex/screens/user_pages/My%20cart/my_cart.dart';
import 'package:bikex/screens/user_pages/check_out%20page/add_payment.dart';
import 'package:bikex/screens/user_pages/check_out%20page/check_out.dart';
import 'package:bikex/screens/user_pages/check_out%20page/successfulpay.dart';
import 'package:bikex/screens/user_pages/food_pages/food_pages.dart';
import 'package:bikex/screens/user_pages/orderHistory%20pages/order_list_page.dart';
import 'package:bikex/screens/user_pages/profile%20pages/personal_profile_page.dart';
import 'package:bikex/screens/user_pages/profile%20pages/profile_page.dart';
import 'package:bikex/screens/user_pages/profile%20pages/addresses_screen.dart';
import 'package:bikex/screens/user_pages/profile%20pages/add_edit_address_screen.dart';
import 'package:bikex/screens/user_pages/payment_pages/payment_methods_screen.dart';
import 'package:bikex/screens/user_pages/payment_pages/transaction_history_screen.dart';
import 'package:bikex/screens/user_pages/restaurant%20_page/restaurant_page.dart';
import 'package:bikex/screens/user_pages/restaurant_map_screen.dart';
import 'package:bikex/screens/user_pages/order_tracking_screen.dart';
import 'package:bikex/screens/debug/mobile_money_test_screen.dart';
import 'package:bikex/screens/user_pages/tracking_pages/track_order_page.dart';
import 'package:bikex/screens/user_pages/tracking_pages/tracking_demo_page.dart';
import 'package:bikex/screens/user_pages/user_credential_pages/forgot_password.dart';
import 'package:bikex/screens/user_pages/user_credential_pages/login.dart';
import 'package:bikex/screens/chef_pages/chef_orders_screen.dart';
import 'package:bikex/screens/user_pages/onboarding%20screens/onboarding_screen.dart';
import 'package:bikex/screens/user_pages/user_credential_pages/signup.dart';
import 'package:bikex/screens/user_pages/user_credential_pages/verification.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  Stripe.publishableKey = 'pk_test_51RPLReD59vYutkQcMxs8ZQvmiQA8AaZOKOp89yK5f5MyOlwWoilzZLPM0VeYC99u1ZHRovFLmcolNzVmL86Rf3u200Xl89OqAz'; // your key
  await Stripe.instance.applySettings();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RestaurantHandler()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BikeX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Sen',
      ),
      home: StreamBuilder<fb.User?>(
        stream: fb.FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const RestaurantDashboard();
          }
          return const LoginPage();
        },
      ),
      routes: {
        '/chef_dashboard': (context) => ChefDashboard(),
        '/personal_profile': (context) => PersonalProfilePage(),
        '/profile': (context) => ProfilePage(),
        '/addresses': (context) => const AddressesScreen(),
        '/add_address': (context) => const AddEditAddressScreen(),
        '/payment_methods': (context) => const PaymentMethodsScreen(),
        '/transaction_history': (context) => const TransactionHistoryScreen(),
        '/order_history': (context) => MyOrdersPage(),
        '/map': (context) => TrackOrderPage(
            order: ModalRoute.of(context)?.settings.arguments as OrderModel?,
          ),
        '/tracking_demo': (context) => const TrackingDemoPage(),
        '/payment_successful': (context) => PaymentSuccessPage(
            order: ModalRoute.of(context)?.settings.arguments as OrderModel?,
          ),
        '/add_payment': (context) => AddCardPage(),
        '/check_out': (context) => CheckOutPage(hasCard: true),
        '/my_cart': (context) => MyCart(),
        '/food_page': (context) =>
            FoodPages(food: ModalRoute.of(context)?.settings.arguments as Food?),
        '/restaurant': (context) => RestaurantPage(
            restaurant: ModalRoute.of(context)?.settings.arguments as Restaurant?),
        '/restaurant_map': (context) => const RestaurantMapScreen(),
        '/order_tracking': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return OrderTrackingScreen(
            restaurant: args?['restaurant'] as Restaurant,
            orderItems: args?['orderItems'] as List<Food>,
            orderNumber: args?['orderNumber'] as String,
            customerLocation: args?['customerLocation'] as LatLng?,
          );
        },
        '/search': (context) => SearchPage(),
        '/dashboard': (context) => const RestaurantDashboard(),
        '/mobile_money_test': (context) => const MobileMoneyTestScreen(),
        '/onboarding1': (context) => OnboardingScreen(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/verification': (context) => const VerificationPage(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/chef/orders': (context) => const ChefOrdersScreen(),
      },
    );
  }
}