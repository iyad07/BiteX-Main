import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  // Initialize notifications
  Future<void> init() async {
    // Request permission for iOS devices
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined permission');
    }

    // Configure local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );

    // Register FCM token with user document
    await _registerDeviceToken();

    // Handle incoming messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Register FCM token to Firestore
  Future<void> _registerDeviceToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) async {
    print("Foreground message received: ${message.notification?.title}");
    
    if (message.notification != null) {
      await _showLocalNotification(
        message.notification!.title ?? 'BiteX',
        message.notification!.body ?? '',
        message.data,
      );
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> payload,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'biteX_channel_id',
      'BiteX Notifications',
      channelDescription: 'Notifications from BiteX app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      platformChannelSpecifics,
      payload: payload.toString(),
    );
  }

  // Handle notification tap when app is in background
  void _handleMessageOpenedApp(RemoteMessage message) {
    print("Background message tapped: ${message.notification?.title}");
    // Handle navigation based on notification data
  }

  // Send notification to specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM tokens
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userTokens = userDoc.data()?['fcmTokens'];
      
      if (userTokens == null || userTokens.isEmpty) return;
      
      // Create notification document
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        // FCM will handle actual delivery to devices
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Send order status notification
  Future<void> sendOrderStatusNotification({
    required String userId,
    required String orderId,
    required String orderStatus,
    required String restaurantName,
  }) async {
    String title = '';
    String body = '';
    
    switch (orderStatus) {
      case 'confirmed':
        title = 'Order Confirmed';
        body = 'Your order from $restaurantName has been confirmed!';
        break;
      case 'preparing':
        title = 'Order Preparation Started';
        body = 'The chef at $restaurantName has started preparing your food.';
        break;
      case 'ready':
        title = 'Order Ready for Pickup';
        body = 'Your order is ready for pickup at $restaurantName.';
        break;
      case 'out_for_delivery':
        title = 'Order Out for Delivery';
        body = 'Your order from $restaurantName is on its way to you!';
        break;
      case 'delivered':
        title = 'Order Delivered';
        body = 'Your order from $restaurantName has been delivered. Enjoy!';
        break;
      case 'cancelled':
        title = 'Order Cancelled';
        body = 'Your order from $restaurantName has been cancelled.';
        break;
      default:
        title = 'Order Update';
        body = 'Your order from $restaurantName has been updated.';
    }
    
    await sendNotificationToUser(
      userId: userId,
      title: title,
      body: body,
      data: {
        'type': 'order_update',
        'orderId': orderId,
        'status': orderStatus,
      },
    );
  }

  // Get user's notifications
  Stream<QuerySnapshot> getUserNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.empty();
    }
    
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .get();
    
    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'read': true});
    }
    
    await batch.commit();
  }

  // Clear all user notifications
  Future<void> clearAllNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .get();
    
    for (var doc in notifications.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
}

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for background handlers
  print("Handling a background message: ${message.messageId}");
}
