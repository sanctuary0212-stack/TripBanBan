import 'package:flutter/material.dart';

IconData categoryIcon(String key) => switch (key) {
      'FOOD' => Icons.restaurant_rounded,
      'STAY' || 'ACCOMMODATION' => Icons.hotel_rounded,
      'TRANSPORT' => Icons.train_rounded,
      'TICKET' => Icons.confirmation_number_rounded,
      'ENTERTAINMENT' => Icons.attractions_rounded,
      'SHOPPING' => Icons.shopping_bag_rounded,
      'COFFEE' => Icons.local_cafe_rounded,
      'SUPERMARKET' => Icons.shopping_cart_rounded,
      _ => Icons.receipt_long_rounded,
    };

String categoryLabel(String key) => switch (key) {
      'FOOD' => '餐飲',
      'STAY' || 'ACCOMMODATION' => '住宿',
      'TRANSPORT' => '交通',
      'TICKET' => '門票',
      'ENTERTAINMENT' => '娛樂',
      'SHOPPING' => '購物',
      'COFFEE' => '咖啡',
      'SUPERMARKET' => '超市',
      'CUSTOM' => '自訂',
      _ => '其他',
    };

const systemCategories = <String>[
  'FOOD',
  'STAY',
  'TRANSPORT',
  'TICKET',
  'ENTERTAINMENT',
  'SHOPPING',
  'COFFEE',
  'SUPERMARKET',
  'OTHER',
];
