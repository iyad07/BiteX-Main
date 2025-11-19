# BiteX RESTful API Endpoints Specification

## Overview
This document provides comprehensive RESTful API endpoint specifications for the BiteX food delivery application backend implementation. The specifications are based on analysis of the Flutter frontend codebase and follow REST conventions with proper authentication, error handling, and documentation standards.

## Base Configuration
- **Base URL**: `https://api.bitex.com/api/v1`
- **Authentication**: Bearer Token (JWT)
- **Content-Type**: `application/json`
- **API Version**: v1

## Data Models & Schemas

### User Model
```json
{
  "id": "string (UUID)",
  "name": "string (2-100 characters)",
  "email": "string (valid email format)",
  "phoneNumber": "string (optional)",
  "address": ["array of strings (optional)"],
  "profileImageUrl": "string (optional, URL format)",
  "userType": "string (enum: customer, chef, admin)",
  "emailVerified": "boolean",
  "createdAt": "string (ISO 8601 datetime)",
  "updatedAt": "string (ISO 8601 datetime, optional)"
}
```

### Restaurant Model
```json
{
  "id": "string (UUID)",
  "restaurantName": "string (required)",
  "restaurantImage": "string (URL format)",
  "rating": "number (0-5, decimal)",
  "deliveryTime": "string (e.g., '30-45 mins')",
  "isFreeDelivery": "boolean",
  "restaurantCategories": "string (comma-separated)",
  "latitude": "number (decimal degrees)",
  "longitude": "number (decimal degrees)",
  "address": "string",
  "phoneNumber": "string",
  "distance": "number (kilometers, calculated field)",
  "isActive": "boolean",
  "createdAt": "string (ISO 8601 datetime)",
  "updatedAt": "string (ISO 8601 datetime, optional)"
}
```

### Food/Menu Item Model
```json
{
  "id": "string (UUID)",
  "foodTitle": "string (required)",
  "foodImage": "string (URL format)",
  "price": "number (decimal, minimum 0)",
  "description": "string (optional)",
  "ingredients": ["array of strings (optional)"],
  "isVegetarian": "boolean",
  "isVegan": "boolean",
  "isGlutenFree": "boolean",
  "preparationTime": "integer (minutes)",
  "category": "string",
  "isAvailable": "boolean",
  "isFeatured": "boolean",
  "allergens": ["array of strings (optional)"],
  "nutritionalInfo": "object (optional)",
  "tags": ["array of strings (optional)"],
  "customizationOptions": "object (optional)",
  "discountPercentage": "number (0-100, optional)",
  "restaurantId": "string (UUID, foreign key)",
  "createdAt": "string (ISO 8601 datetime)",
  "updatedAt": "string (ISO 8601 datetime, optional)"
}
```

### Order Model
```json
{
  "id": "string (UUID)",
  "orderNumber": "string (unique identifier)",
  "userId": "string (UUID, foreign key)",
  "restaurantId": "string (UUID, foreign key)",
  "restaurant": "Restaurant object (populated)",
  "items": ["array of CartItem objects"],
  "totalPrice": "number (decimal)",
  "deliveryAddress": "string",
  "customerName": "string",
  "customerPhone": "string",
  "orderTime": "string (ISO 8601 datetime)",
  "status": "string (enum: pending, preparing, ready, completed, cancelled)",
  "notes": "string (optional)",
  "paymentMethodId": "string (UUID, foreign key)",
  "paymentStatus": "string (enum: pending, completed, failed, refunded)",
  "estimatedDeliveryTime": "string (ISO 8601 datetime, optional)",
  "actualDeliveryTime": "string (ISO 8601 datetime, optional)",
  "createdAt": "string (ISO 8601 datetime)",
  "updatedAt": "string (ISO 8601 datetime, optional)"
}
```

### Cart Item Model
```json
{
  "id": "string (UUID)",
  "foodId": "string (UUID, foreign key)",
  "food": "Food object (populated)",
  "quantity": "integer (minimum 1)",
  "notes": "string (optional)",
  "isPrepared": "boolean",
  "subtotal": "number (calculated: food.price * quantity)"
}
```

### Payment Method Model
```json
{
  "id": "string (UUID)",
  "userId": "string (UUID, foreign key)",
  "type": "string (enum: creditCard, debitCard, paypal, applePay, googlePay, cashOnDelivery, mtnMobileMoney, vodafoneCash, airtelTigoMoney, mobileMoney, paystack)",
  "title": "string (user-defined name)",
  "lastFourDigits": "string (optional, for cards)",
  "cardHolderName": "string (optional, for cards)",
  "expiryDate": "string (optional, MM/YY format)",
  "brand": "string (optional, e.g., Visa, Mastercard)",
  "isDefault": "boolean",
  "billingAddressId": "string (UUID, foreign key, optional)",
  "paymentTokenId": "string (optional, for stored payment methods)",
  "gatewayData": "object (optional, gateway-specific data)",
  "createdAt": "string (ISO 8601 datetime)",
  "updatedAt": "string (ISO 8601 datetime, optional)"
}
```

### Address Model
```json
{
  "id": "string (UUID)",
  "userId": "string (UUID, foreign key)",
  "title": "string (e.g., Home, Work)",
  "addressLine1": "string (required)",
  "addressLine2": "string (optional)",
  "city": "string (required)",
  "state": "string (required)",
  "postalCode": "string (required)",
  "country": "string (required)",
  "latitude": "number (decimal degrees, optional)",
  "longitude": "number (decimal degrees, optional)",
  "instructions": "string (optional, delivery instructions)",
  "isDefault": "boolean",
  "label": "string (optional, additional label)",
  "createdAt": "string (ISO 8601 datetime)",
  "updatedAt": "string (ISO 8601 datetime, optional)"
}
```

### Review Model
```json
{
  "id": "string (UUID)",
  "userId": "string (UUID, foreign key)",
  "userName": "string (populated from user)",
  "restaurantId": "string (UUID, foreign key)",
  "foodId": "string (UUID, foreign key, optional)",
  "rating": "integer (1-5)",
  "comment": "string (10-500 characters)",
  "images": ["array of strings (URLs, optional, max 5)"],
  "createdAt": "string (ISO 8601 datetime)"
}
```

### Chef Model
```json
{
  "id": "string (UUID)",
  "name": "string (required)",
  "email": "string (valid email format)",
  "phoneNumber": "string (optional)",
  "profileImageUrl": "string (optional, URL format)",
  "restaurantId": "string (UUID, foreign key)",
  "speciality": "string (optional)",
  "bio": "string (optional)",
  "certificates": ["array of strings (optional)"],
  "joinDate": "string (ISO 8601 datetime)",
  "isActive": "boolean"
}
```

## Authentication & Authorization

### Authentication Endpoints

#### POST /auth/register
**Description**: Register a new user account
**Authentication**: None required
**Request Body**:
```json
{
  "name": "string (required, min: 2, max: 100)",
  "email": "string (required, valid email format)",
  "password": "string (required, min: 8, max: 128)",
  "phoneNumber": "string (optional, valid phone format)",
  "userType": "string (required, enum: ['customer', 'chef', 'admin'])"
}
```
**Response**:
- **201 Created**:
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "userId": "string",
    "email": "string",
    "name": "string",
    "userType": "string",
    "emailVerified": false,
    "createdAt": "ISO 8601 datetime"
  },
  "token": "JWT token string"
}
```
- **400 Bad Request**: Validation errors
- **409 Conflict**: Email already exists
- **500 Internal Server Error**: Server error

#### POST /auth/login
**Description**: Authenticate user and get access token
**Authentication**: None required
**Request Body**:
```json
{
  "email": "string (required)",
  "password": "string (required)"
}
```
**Response**:
- **200 OK**:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "userId": "string",
    "email": "string",
    "name": "string",
    "userType": "string",
    "emailVerified": boolean,
    "lastLoginAt": "ISO 8601 datetime"
  },
  "token": "JWT token string"
}
```
- **401 Unauthorized**: Invalid credentials
- **403 Forbidden**: Account not verified
- **500 Internal Server Error**: Server error

#### POST /auth/logout
**Description**: Logout user and invalidate token
**Authentication**: Bearer Token required
**Response**:
- **200 OK**:
```json
{
  "success": true,
  "message": "Logout successful"
}
```

#### POST /auth/refresh-token
**Description**: Refresh access token
**Authentication**: Bearer Token required
**Response**:
- **200 OK**:
```json
{
  "success": true,
  "token": "new JWT token string"
}
```

#### POST /auth/forgot-password
**Description**: Send password reset email
**Authentication**: None required
**Request Body**:
```json
{
  "email": "string (required)"
}
```
**Response**:
- **200 OK**:
```json
{
  "success": true,
  "message": "Password reset email sent"
}
```

#### POST /auth/reset-password
**Description**: Reset password with token
**Authentication**: None required
**Request Body**:
```json
{
  "token": "string (required)",
  "newPassword": "string (required, min: 8)"
}
```
**Response**:
- **200 OK**:
```json
{
  "success": true,
  "message": "Password reset successful"
}
```

## User Management

### User Profile Endpoints

#### GET /users/profile
**Description**: Get current user profile
**Authentication**: Bearer Token required
**Response**:
- **200 OK**:
```json
{
  "success": true,
  "data": {
    "id": "string",
    "name": "string",
    "email": "string",
    "phoneNumber": "string",
    "address": ["string array"],
    "profileImageUrl": "string (optional)",
    "userType": "string",
    "createdAt": "ISO 8601 datetime",
    "updatedAt": "ISO 8601 datetime"
  }
}
```

#### PUT /users/profile
**Description**: Update user profile
**Authentication**: Bearer Token required
**Request Body**:
```json
{
  "name": "string (optional)",
  "phoneNumber": "string (optional)",
  "address": ["string array (optional)"],
  "profileImageUrl": "string (optional)"
}
```
**Response**:
- **200 OK**: Updated user profile data
- **400 Bad Request**: Validation errors

#### DELETE /users/profile
**Description**: Delete user account
**Authentication**: Bearer Token required
**Response**:
- **200 OK**:
```json
{
  "success": true,
  "message": "Account deleted successfully"
}
```

## Restaurant Management

### Restaurant Endpoints

#### GET /restaurants
**Description**: Get list of restaurants with filtering and pagination
**Authentication**: Bearer Token required
**Query Parameters**:
- `page`: integer (default: 1)
- `limit`: integer (default: 20, max: 100)
- `category`: string (optional)
- `latitude`: number (optional, for location-based search)
- `longitude`: number (optional, for location-based search)
- `radius`: number (optional, in kilometers, default: 10)
- `search`: string (optional, search by name)
- `sortBy`: string (enum: ['rating', 'deliveryTime', 'distance'], default: 'rating')
- `sortOrder`: string (enum: ['asc', 'desc'], default: 'desc')

**Response**:
- **200 OK**:
```json
{
  "success": true,
  "data": {
    "restaurants": [
      {
        "id": "string",
        "restaurantName": "string",
        "restaurantImage": "string",
        "rating": "number",
        "deliveryTime": "string",
        "isFreeDelivery": "boolean",
        "restaurantCategories": "string",
        "latitude": "number",
        "longitude": "number",
        "address": "string",
        "phoneNumber": "string",
        "distance": "number (if location provided)"
      }
    ],
    "pagination": {
      "currentPage": "number",
      "totalPages": "number",
      "totalItems": "number",
      "hasNext": "boolean",
      "hasPrev": "boolean"
    }
  }
}
```

#### GET /restaurants/{restaurantId}
**Description**: Get restaurant details with menu
**Authentication**: Bearer Token required
**Response**:
- **200 OK**:
```json
{
  "success": true,
  "data": {
    "id": "string",
    "restaurantName": "string",
    "restaurantImage": "string",
    "rating": "number",
    "deliveryTime": "string",
    "isFreeDelivery": "boolean",
    "restaurantCategories": "string",
    "latitude": "number",
    "longitude": "number",
    "address": "string",
    "phoneNumber": "string",
    "foodList": [
      {
        "id": "string",
        "foodTitle": "string",
        "foodImage": "string",
        "price": "number",
        "description": "string",
        "ingredients": ["string array"],
        "isVegetarian": "boolean",
        "isVegan": "boolean",
        "isGlutenFree": "boolean",
        "preparationTime": "number"
      }
    ]
  }
}
```

#### POST /restaurants
**Description**: Create new restaurant (Chef/Admin only)
**Authentication**: Bearer Token required (Chef/Admin role)
**Request Body**:
```json
{
  "restaurantName": "string (required)",
  "restaurantImage": "string (required)",
  "restaurantCategories": "string (required)",
  "latitude": "number (optional)",
  "longitude": "number (optional)",
  "address": "string (optional)",
  "phoneNumber": "string (optional)"
}
```
**Response**:
- **201 Created**: Restaurant created successfully
- **403 Forbidden**: Insufficient permissions

#### PUT /restaurants/{restaurantId}
**Description**: Update restaurant details
**Authentication**: Bearer Token required (Restaurant owner/Admin)
**Request Body**: Same as POST with optional fields
**Response**:
- **200 OK**: Updated restaurant data
- **403 Forbidden**: Not authorized to update this restaurant

#### DELETE /restaurants/{restaurantId}
**Description**: Delete restaurant
**Authentication**: Bearer Token required (Restaurant owner/Admin)
**Response**:
- **200 OK**: Restaurant deleted successfully

## Menu Management

### Menu Item Endpoints

#### GET /restaurants/{restaurantId}/menu
**Description**: Get restaurant menu items
**Authentication**: Bearer Token required
**Query Parameters**:
- `category`: string (optional)
- `isFeatured`: boolean (optional)
- `isAvailable`: boolean (optional, default: true)

**Response**:
- **200 OK**:
```json
{
  "success": true,
  "data": {
    "menuItems": [
      {
        "id": "string",
        "name": "string",
        "description": "string",
        "price": "number",
        "category": "string",
        "imageUrl": "string",
        "isAvailable": "boolean",
        "isFeatured": "boolean",
        "allergens": ["string array"],
        "nutritionalInfo": "object",
        "tags": ["string array"],
        "customizationOptions": "object",
        "discountPercentage": "number",
        "preparationTime": "number",
        "createdAt": "ISO 8601 datetime",
        "updatedAt": "ISO 8601 datetime"
      }
    ],
    "categories": ["string array"]
  }
}
```

#### POST /restaurants/{restaurantId}/menu
**Description**: Add new menu item
**Authentication**: Bearer Token required (Restaurant owner/Chef)
**Request Body**:
```json
{
  "name": "string (required)",
  "description": "string (optional)",
  "price": "number (required, min: 0)",
  "category": "string (required)",
  "imageUrl": "string (optional)",
  "isAvailable": "boolean (default: true)",
  "isFeatured": "boolean (default: false)",
  "allergens": ["string array (optional)"],
  "nutritionalInfo": "object (optional)",
  "tags": ["string array (optional)"],
  "customizationOptions": "object (optional)",
  "discountPercentage": "number (optional, min: 0, max: 100)",
  "preparationTime": "number (optional, default: 15)"
}
```
**Response**:
- **201 Created**: Menu item created successfully

#### PUT /restaurants/{restaurantId}/menu/{itemId}
**Description**: Update menu item
**Authentication**: Bearer Token required (Restaurant owner/Chef)
**Request Body**: Same as POST with optional fields
**Response**:
- **200 OK**: Menu item updated successfully

#### DELETE /restaurants/{restaurantId}/menu/{itemId}
**Description**: Delete menu item
**Authentication**: Bearer Token required (Restaurant owner/Chef)
**Response**:
- **200 OK**: Menu item deleted successfully

#### GET /restaurants/{restaurantId}/menu/categories
**Description**: Get menu categories for restaurant
**Authentication**: Bearer Token required
**Response**:
- **200 OK**:
```json
{
  "success": true,
  "data": {
    "categories": ["string array"]
  }
}
```

## Order Management

### Order Endpoints

#### POST /orders
**Description**: Create new order
**Authentication**: Bearer Token required
**Request Body**:
```json
{
  "restaurantId": "string (required)",
  "items": [
    {
      "foodId": "string (required)",
      "quantity": "number (required, min: 1)",
      "notes": "string (optional)"
    }
  ],
  "deliveryAddress": "string (required)",
  "customerName": "string (required)",
  "customerPhone": "string (required)",
  "paymentMethodId": "string (required)",
  "notes": "string (optional)"
}
```
**Response**:
- **201 Created**:
```json
{
  "success": true,
  "message": "Order created successfully",
  "data": {
    "orderId": "string",
    "orderNumber": "string",
    "status": "pending",
    "totalPrice": "number",
    "estimatedDeliveryTime": "ISO 8601 datetime",
    "paymentStatus": "string"
  }
}
```

#### GET /orders
**Description**: Get user's orders with pagination
**Authentication**: Bearer Token required
**Query Parameters**:
- `page`: integer (default: 1)
- `limit`: integer (default: 20)
- `status`: string (optional, enum: ['pending', 'preparing', 'ready', 'completed', 'cancelled'])

**Response**:
- **200 OK**:
```json
{
  "success": true,
  "data": {
    "orders": [
      {
        "id": "string",
        "orderNumber": "string",
        "restaurant": "restaurant object",
        "items": ["cart item array"],
        "totalPrice": "number",
        "deliveryAddress": "string",
        "customerName": "string",
        "customerPhone": "string",
        "orderTime": "ISO 8601 datetime",
        "status": "string",
        "notes": "string",
        "paymentStatus": "string"
      }
    ],
    "pagination": "pagination object"
  }
}
```

#### GET /orders/{orderId}
**Description**: Get specific order details
**Authentication**: Bearer Token required
**Response**:
- **200 OK**: Detailed order information
- **404 Not Found**: Order not found
- **403 Forbidden**: Not authorized to view this order

#### PUT /orders/{orderId}/status
**Description**: Update order status (Chef/Admin only)
**Authentication**: Bearer Token required (Chef/Admin role)
**Request Body**:
```json
{
  "status": "string (required, enum: ['pending', 'preparing', 'ready', 'completed', 'cancelled'])",
  "notes": "string (optional)"
}
```
**Response**:
- **200 OK**: Order status updated successfully

#### DELETE /orders/{orderId}
**Description**: Cancel order (if status allows)
**Authentication**: Bearer Token required
**Response**:
- **200 OK**: Order cancelled successfully
- **400 Bad Request**: Cannot cancel order in current status

### Chef Order Management

#### GET /chef/orders
**Description**: Get orders for chef's restaurant
**Authentication**: Bearer Token required (Chef role)
**Query Parameters**:
- `status`: string (optional)
- `date`: string (optional, ISO date format)
- `page`: integer (default: 1)
- `limit`: integer (default: 20)

**Response**:
- **200 OK**: List of orders for chef's restaurant

#### PUT /chef/orders/{orderId}/items/{itemId}/prepared
**Description**: Mark order item as prepared
**Authentication**: Bearer Token required (Chef role)
**Response**:
- **200 OK**: Item marked as prepared

## Cart Management

### Cart Endpoints

#### GET /cart
**Description**: Get user's current cart
**Authentication**: Bearer Token required
**Response**:
- **200 OK**:
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "string",
        "food": "food object",
        "quantity": "number",
        "notes": "string",
        "subtotal": "number"
      }
    ],
    "totalItems": "number",
    "totalPrice": "number",
    "restaurantId": "string"
  }
}
```

#### POST /cart/items
**Description**: Add item to cart
**Authentication**: Bearer Token required
**Request Body**:
```json
{
  "foodId": "string (required)",
  "quantity": "number (required, min: 1)",
  "notes": "string (optional)"
}
```
**Response**:
- **201 Created**: Item added to cart
- **400 Bad Request**: Cannot add items from different restaurants

#### PUT /cart/items/{itemId}
**Description**: Update cart item
**Authentication**: Bearer Token required
**Request Body**:
```json
{
  "quantity": "number (optional, min: 1)",
  "notes": "string (optional)"
}
```
**Response**:
- **200 OK**: Cart item updated

#### DELETE /cart/items/{itemId}
**Description**: Remove item from cart
**Authentication**: Bearer Token required
**Response**:
- **200 OK**: Item removed from cart

#### DELETE /cart
**Description**: Clear entire cart
**Authentication**: Bearer Token required
**Response**:
- **200 OK**: Cart cleared

## Payment Management

### Payment Method Endpoints

#### GET /payment-methods
**Description**: Get user's payment methods
**Authentication**: Bearer Token required
**Response**:
- **200 OK**:
```json
{
  "success": true,
  "data": {
    "paymentMethods": [
      {
        "id": "string",
        "type": "string",
        "title": "string",
        "lastFourDigits": "string",
        "cardHolderName": "string",
        "expiryDate": "string",
        "brand": "string",
        "isDefault": "boolean",
        "createdAt": "ISO 8601 datetime"
      }
    ]
  }
}
```

#### POST /payment-methods
**Description**: Add new payment method
**Authentication**: Bearer Token required
**Request Body**:
```json
{
  "type": "string (required, enum: ['creditCard', 'debitCard', 'paypal', 'applePay', 'googlePay', 'cashOnDelivery', 'mtnMobileMoney', 'vodafoneCash', 'airtelTigoMoney', 'mobileMoney', 'paystack'])",
  "title": "string (required)",
  "cardNumber": "string (required for card types)",
  "expiryDate": "string (required for card types, MM/YY format)",
  "cvv": "string (required for card types)",
  "cardHolderName": "string (required for card types)",
  "isDefault": "boolean (default: false)",
  "billingAddressId": "string (optional)"
}
```
**Response**:
- **201 Created**: Payment method added successfully

#### PUT /payment-methods/{paymentMethodId}
**Description**: Update payment method
**Authentication**: Bearer Token required
**Request Body**: Partial payment method data
**Response**:
- **200 OK**: Payment method updated

#### DELETE /payment-methods/{paymentMethodId}
**Description**: Delete payment method
**Authentication**: Bearer Token required
**Response**:
- **200 OK**: Payment method deleted

#### PUT /payment-methods/{paymentMethodId}/default
**Description**: Set payment method as default
**Authentication**: Bearer Token required
**Response**:
- **200 OK**: Default payment method updated

### Transaction Endpoints

#### GET /transactions
**Description**: Get user's transaction history
**Authentication**: Bearer Token required
**Query Parameters**:
- `page`: integer (default: 1)
- `limit`: integer (default: 20)
- `status`: string (optional)
- `startDate`: string (optional, ISO date)
- `endDate`: string (optional, ISO date)

**Response**:
- **200 OK**:
```json
{
  "success": true,
  "data": {
    "transactions": [
      {
        "id": "string",
        "orderId": "string",
        "amount": "number",
        "currency": "string",
        "status": "string",
        "paymentMethod": "string",
        "gatewayTransactionId": "string",
        "timestamp": "ISO 8601 datetime",
        "description": "string"
      }
    ],
    "pagination": "pagination object"
  }
}
```

#### POST /transactions/process-payment
**Description**: Process payment for order
**Authentication**: Bearer Token required
**Request Body**:
```json
{
  "orderId": "string (required)",
  "paymentMethodId": "string (required)",
  "amount": "number (required)"
}
```
**Response**:
- **200 OK**: Payment processed successfully
- **400 Bad Request**: Payment failed

## Address Management

### Address Endpoints

#### GET /addresses
**Description**: Get user's saved addresses
**Authentication**: Bearer Token required
**Response**:
- **200 OK**:
```json
{
  "success": true,
  "data": {
    "addresses": [
      {
        "id": "string",
        "title": "string",
        "addressLine1": "string",
        "addressLine2": "string",
        "city": "string",
        "state": "string",
        "postalCode": "string",
        "country": "string",
        "latitude": "number",
        "longitude": "number",
        "instructions": "string",
        "isDefault": "boolean",
        "label": "string",
        "createdAt": "ISO 8601 datetime"
      }
    ]
  }
}
```

#### POST /addresses
**Description**: Add new address
**Authentication**: Bearer Token required
**Request Body**:
```json
{
  "title": "string (required)",
  "addressLine1": "string (required)",
  "addressLine2": "string (optional)",
  "city": "string (required)",
  "state": "string (required)",
  "postalCode": "string (required)",
  "country": "string (required)",
  "latitude": "number (required)",
  "longitude": "number (required)",
  "instructions": "string (optional)",
  "isDefault": "boolean (default: false)",
  "label": "string (optional)"
}
```
**Response**:
- **201 Created**: Address added successfully

#### PUT /addresses/{addressId}
**Description**: Update address
**Authentication**: Bearer Token required
**Request Body**: Partial address data
**Response**:
- **200 OK**: Address updated successfully

#### DELETE /addresses/{addressId}
**Description**: Delete address
**Authentication**: Bearer Token required
**Response**:
- **200 OK**: Address deleted successfully

#### PUT /addresses/{addressId}/default
**Description**: Set address as default
**Authentication**: Bearer Token required
**Response**:
- **200 OK**: Default address updated

## Review Management

### Review Endpoints

#### GET /restaurants/{restaurantId}/reviews
**Description**: Get restaurant reviews
**Authentication**: Bearer Token required
**Query Parameters**:
- `page`: integer (default: 1)
- `limit`: integer (default: 20)
- `rating`: integer (optional, filter by rating)

**Response**:
- **200 OK**:
```json
{
  "success": true,
  "data": {
    "reviews": [
      {
        "id": "string",
        "userId": "string",
        "userName": "string",
        "restaurantId": "string",
        "foodId": "string",
        "rating": "number",
        "comment": "string",
        "createdAt": "ISO 8601 datetime",
        "images": ["string array"]
      }
    ],
    "averageRating": "number",
    "totalReviews": "number",
    "ratingDistribution": {
      "5": "number",
      "4": "number",
      "3": "number",
      "2": "number",
      "1": "number"
    },
    "pagination": "pagination object"
  }
}
```

#### POST /restaurants/{restaurantId}/reviews
**Description**: Add restaurant review
**Authentication**: Bearer Token required
**Request Body**:
```json
{
  "rating": "number (required, min: 1, max: 5)",
  "comment": "string (required, min: 10, max: 500)",
  "foodId": "string (optional)",
  "images": ["string array (optional, max: 5 images)"]
}
```
**Response**:
- **201 Created**: Review added successfully
- **400 Bad Request**: User hasn't ordered from this restaurant

#### PUT /reviews/{reviewId}
**Description**: Update review
**Authentication**: Bearer Token required (Review owner only)
**Request Body**: Partial review data
**Response**:
- **200 OK**: Review updated successfully

#### DELETE /reviews/{reviewId}
**Description**: Delete review
**Authentication**: Bearer Token required (Review owner only)
**Response**:
- **200 OK**: Review deleted successfully

## Notification Management

### Notification Endpoints

#### GET /notifications
**Description**: Get user notifications
**Authentication**: Bearer Token required
**Query Parameters**:
- `page`: integer (default: 1)
- `limit`: integer (default: 20)
- `isRead`: boolean (optional)

**Response**:
- **200 OK**:
```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "string",
        "title": "string",
        "body": "string",
        "type": "string",
        "data": "object",
        "isRead": "boolean",
        "createdAt": "ISO 8601 datetime"
      }
    ],
    "unreadCount": "number",
    "pagination": "pagination object"
  }
}
```

#### PUT /notifications/{notificationId}/read
**Description**: Mark notification as read
**Authentication**: Bearer Token required
**Response**:
- **200 OK**: Notification marked as read

#### PUT /notifications/read-all
**Description**: Mark all notifications as read
**Authentication**: Bearer Token required
**Response**:
- **200 OK**: All notifications marked as read

#### DELETE /notifications/{notificationId}
**Description**: Delete notification
**Authentication**: Bearer Token required
**Response**:
- **200 OK**: Notification deleted

## Search & Discovery

### Search Endpoints

#### GET /search/restaurants
**Description**: Search restaurants
**Authentication**: Bearer Token required
**Query Parameters**:
- `q`: string (required, search query)
- `category`: string (optional)
- `latitude`: number (optional)
- `longitude`: number (optional)
- `radius`: number (optional, in km)
- `page`: integer (default: 1)
- `limit`: integer (default: 20)

**Response**:
- **200 OK**: Search results with restaurants

#### GET /search/food
**Description**: Search food items across restaurants
**Authentication**: Bearer Token required
**Query Parameters**:
- `q`: string (required, search query)
- `category`: string (optional)
- `isVegetarian`: boolean (optional)
- `isVegan`: boolean (optional)
- `isGlutenFree`: boolean (optional)
- `maxPrice`: number (optional)
- `page`: integer (default: 1)
- `limit`: integer (default: 20)

**Response**:
- **200 OK**: Search results with food items

#### GET /search/suggestions
**Description**: Get search suggestions
**Authentication**: Bearer Token required
**Query Parameters**:
- `q`: string (required, partial query)
- `type`: string (optional, enum: ['restaurants', 'food', 'both'])

**Response**:
- **200 OK**:
```json
{
  "success": true,
  "data": {
    "suggestions": [
      {
        "text": "string",
        "type": "string",
        "id": "string"
      }
    ]
  }
}
```

## Analytics & Reporting (Chef/Admin)

### Analytics Endpoints

#### GET /chef/analytics/dashboard
**Description**: Get chef dashboard analytics
**Authentication**: Bearer Token required (Chef role)
**Query Parameters**:
- `period`: string (enum: ['today', 'week', 'month', 'year'], default: 'today')

**Response**:
- **200 OK**:
```json
{
  "success": true,
  "data": {
    "totalOrders": "number",
    "totalRevenue": "number",
    "averageOrderValue": "number",
    "popularItems": ["menu item array"],
    "ordersByStatus": "object",
    "revenueChart": ["chart data array"],
    "orderTrends": ["trend data array"]
  }
}
```

#### GET /chef/analytics/orders
**Description**: Get detailed order analytics
**Authentication**: Bearer Token required (Chef role)
**Query Parameters**:
- `startDate`: string (ISO date)
- `endDate`: string (ISO date)
- `groupBy`: string (enum: ['day', 'week', 'month'])

**Response**:
- **200 OK**: Detailed order analytics

#### GET /chef/analytics/menu-performance
**Description**: Get menu item performance analytics
**Authentication**: Bearer Token required (Chef role)
**Response**:
- **200 OK**: Menu performance data

## Error Handling

### Standard Error Response Format
```json
{
  "success": false,
  "error": {
    "code": "string",
    "message": "string",
    "details": "object (optional)"
  },
  "timestamp": "ISO 8601 datetime",
  "path": "string"
}
```

### Common HTTP Status Codes
- **200 OK**: Request successful
- **201 Created**: Resource created successfully
- **400 Bad Request**: Invalid request data
- **401 Unauthorized**: Authentication required
- **403 Forbidden**: Insufficient permissions
- **404 Not Found**: Resource not found
- **409 Conflict**: Resource already exists
- **422 Unprocessable Entity**: Validation errors
- **429 Too Many Requests**: Rate limit exceeded
- **500 Internal Server Error**: Server error

### Error Codes
- `VALIDATION_ERROR`: Request validation failed
- `AUTHENTICATION_REQUIRED`: User not authenticated
- `INSUFFICIENT_PERMISSIONS`: User lacks required permissions
- `RESOURCE_NOT_FOUND`: Requested resource not found
- `DUPLICATE_RESOURCE`: Resource already exists
- `PAYMENT_FAILED`: Payment processing failed
- `ORDER_CANNOT_BE_MODIFIED`: Order status doesn't allow modification
- `RESTAURANT_CLOSED`: Restaurant is currently closed
- `ITEM_OUT_OF_STOCK`: Menu item is not available

## Rate Limiting

### Rate Limit Configuration
- **Authentication endpoints**: 5 requests per minute per IP
- **General API endpoints**: 100 requests per minute per user
- **Search endpoints**: 30 requests per minute per user
- **File upload endpoints**: 10 requests per minute per user

### Rate Limit Headers
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
```

## Security Considerations

### Authentication
- JWT tokens with 24-hour expiration
- Refresh tokens with 30-day expiration
- Secure token storage recommendations

### Data Validation
- Input sanitization for all endpoints
- SQL injection prevention
- XSS protection
- CSRF protection

### API Security
- HTTPS only
- CORS configuration
- Request size limits
- File upload restrictions

## OpenAPI/Swagger Compatibility

This API specification is designed to be fully compatible with OpenAPI 3.0 specification and can be easily converted to Swagger documentation format. Key features include:

- Standardized request/response schemas
- Comprehensive parameter documentation
- Authentication scheme definitions
- Error response specifications
- Example request/response payloads

## Backend Implementation Guidelines

### Database Architecture
- Use appropriate indexes for frequently queried fields (`userId`, `restaurantId`, `orderId`, `createdAt`)
- Implement soft deletes for critical data (orders, users, restaurants)
- Consider data archiving strategy for historical orders and transactions
- Implement proper foreign key constraints and referential integrity
- Use database triggers for automatic timestamp updates

### Performance & Scalability
- Implement Redis caching for frequently accessed data (restaurant menus, user profiles)
- Use pagination for all list endpoints with configurable page sizes
- Optimize database queries with proper indexing and query analysis
- Consider CDN integration for static assets (images, documents)
- Implement connection pooling for database connections
- Use database read replicas for read-heavy operations

### Security Implementation
- Implement JWT token-based authentication with refresh tokens
- Use bcrypt for password hashing with appropriate salt rounds
- Implement rate limiting per endpoint and per user
- Add request validation and sanitization
- Use HTTPS only with proper SSL/TLS configuration
- Implement CORS policies for frontend integration
- Add request logging for security auditing

### Monitoring & Observability
- Implement comprehensive API logging with structured formats
- Monitor response times, error rates, and throughput metrics
- Set up alerts for critical failures and performance degradation
- Track business metrics (orders per hour, revenue, user activity)
- Implement health check endpoints for service monitoring
- Use distributed tracing for complex request flows

### Error Handling & Resilience
- Implement circuit breaker patterns for external service calls
- Add retry mechanisms with exponential backoff
- Provide detailed error messages with proper HTTP status codes
- Implement graceful degradation for non-critical features
- Add request timeout configurations
- Use dead letter queues for failed async operations

This specification provides a comprehensive foundation for implementing the BiteX backend API while maintaining consistency with the existing Flutter frontend architecture and following REST best practices.