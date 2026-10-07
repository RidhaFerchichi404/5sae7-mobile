import 'package:flutter/material.dart';

IconData iconForKey(String key) {
  return switch (key) {
    'restaurant' => Icons.restaurant,
    'directions_car' => Icons.directions_car,
    'home' => Icons.home,
    'medical_services' => Icons.medical_services,
    'shopping_bag' => Icons.shopping_bag,
    'movie' => Icons.movie,
    'school' => Icons.school,
    'receipt_long' => Icons.receipt_long,
    'category' => Icons.category,
    'payments' => Icons.payments,
    'work' => Icons.work,
    'card_giftcard' => Icons.card_giftcard,
    'savings' => Icons.savings,
    'pets' => Icons.pets,
    'flight' => Icons.flight,
    'fitness_center' => Icons.fitness_center,
    'child_care' => Icons.child_care,
    'phone_iphone' => Icons.phone_iphone,
    'local_cafe' => Icons.local_cafe,
    'more_horiz' => Icons.more_horiz,
    _ => Icons.category,
  };
}
