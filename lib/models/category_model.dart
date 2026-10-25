import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String? userId;
  final String name;
  final String emoji;
  final String colorHex;
  final bool isDefault;
  final String? iconName;

  CategoryModel({
    required this.id,
    this.userId,
    required this.name,
    required this.emoji,
    this.colorHex = '#111111',
    this.isDefault = false,
    this.iconName,
  });

  CategoryModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? emoji,
    String? colorHex,
    bool? isDefault,
    String? iconName,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault ?? this.isDefault,
      iconName: iconName ?? this.iconName,
    );
  }

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '').trim();
      if (hex.isEmpty ||
          hex.toUpperCase() == '111111' ||
          hex.toUpperCase() == '000000' ||
          hex.toUpperCase() == 'FF111111') {
        return getDefaultColorForName(name);
      }
      return Color(int.parse('0xFF$hex'));
    } catch (_) {
      return getDefaultColorForName(name);
    }
  }

  static Color getDefaultColorForName(String categoryName) {
    switch (categoryName.toLowerCase().trim()) {
      case 'coffee':
        return const Color(0xFFF59E0B); // Amber
      case 'pet care':
      case 'pet':
        return const Color(0xFFEC4899); // Pink
      case 'commute':
      case 'transport':
        return const Color(0xFF3B82F6); // Electric Blue
      case 'house repair':
      case 'repair':
        return const Color(0xFF8B5CF6); // Purple
      case 'food & snacks':
      case 'food':
        return const Color(0xFFF97316); // Warm Orange
      case 'groceries':
        return const Color(0xFF10B981); // Emerald Green
      case 'shopping':
        return const Color(0xFFD946EF); // Fuchsia
      case 'bills & utilities':
      case 'bills':
      case 'utilities':
        return const Color(0xFFEAB308); // Yellow / Gold
      case 'health':
        return const Color(0xFFEF4444); // Red
      case 'other':
      default:
        return const Color(0xFF06B6D4); // Cyan
    }
  }

  static String getDefaultColorHexForName(String categoryName) {
    switch (categoryName.toLowerCase().trim()) {
      case 'coffee':
        return '#F59E0B';
      case 'pet care':
      case 'pet':
        return '#EC4899';
      case 'commute':
      case 'transport':
        return '#3B82F6';
      case 'house repair':
      case 'repair':
        return '#8B5CF6';
      case 'food & snacks':
      case 'food':
        return '#F97316';
      case 'groceries':
        return '#10B981';
      case 'shopping':
        return '#D946EF';
      case 'bills & utilities':
      case 'bills':
      case 'utilities':
        return '#EAB308';
      case 'health':
        return '#EF4444';
      case 'other':
      default:
        return '#06B6D4';
    }
  }

  IconData get icon {
    if (iconName != null && iconName!.isNotEmpty) {
      final customIcon = getIconByName(iconName!);
      if (customIcon != null) return customIcon;
    }
    return getIconForName(name);
  }

  IconData get iconData => icon;

  static IconData? getIconByName(String key) {
    switch (key.toLowerCase().trim()) {
      case 'sports_esports':
      case 'game':
      case 'gaming':
        return Icons.sports_esports_rounded;
      case 'fitness_center':
      case 'gym':
      case 'fitness':
      case 'sport':
        return Icons.fitness_center_rounded;
      case 'flight':
      case 'flight_takeoff':
      case 'travel':
        return Icons.flight_takeoff_rounded;
      case 'movie':
      case 'movies':
      case 'cinema':
        return Icons.movie_rounded;
      case 'music_note':
      case 'music':
        return Icons.music_note_rounded;
      case 'subscriptions':
      case 'subscription':
        return Icons.subscriptions_rounded;
      case 'school':
      case 'education':
      case 'study':
        return Icons.school_rounded;
      case 'card_giftcard':
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'trending_up':
      case 'investment':
        return Icons.trending_up_rounded;
      case 'savings':
      case 'saving':
        return Icons.savings_rounded;
      case 'work':
      case 'business':
        return Icons.work_rounded;
      case 'restaurant':
      case 'dining':
        return Icons.restaurant_rounded;
      case 'spa':
      case 'beauty':
      case 'salon':
        return Icons.spa_rounded;
      case 'checkroom':
      case 'clothing':
      case 'clothes':
        return Icons.checkroom_rounded;
      case 'local_gas_station':
      case 'fuel':
      case 'gas':
        return Icons.local_gas_station_rounded;
      case 'two_wheeler':
      case 'bike':
      case 'motorcycle':
        return Icons.two_wheeler_rounded;
      case 'wifi':
      case 'internet':
        return Icons.wifi_rounded;
      case 'palette':
      case 'art':
      case 'hobby':
        return Icons.palette_rounded;
      case 'water_drop':
      case 'water':
        return Icons.water_drop_rounded;
      case 'book':
      case 'books':
        return Icons.book_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'coffee':
      case 'local_cafe':
        return Icons.local_cafe_rounded;
      case 'pet':
      case 'pets':
        return Icons.pets_rounded;
      case 'commute':
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'repair':
      case 'build':
        return Icons.build_rounded;
      case 'food':
      case 'fastfood':
        return Icons.fastfood_rounded;
      case 'groceries':
      case 'shopping_cart':
        return Icons.shopping_cart_rounded;
      case 'shopping':
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'bills':
      case 'bolt':
        return Icons.bolt_rounded;
      case 'health':
      case 'medical_services':
        return Icons.medical_services_rounded;
      case 'inventory_2':
      case 'other':
        return Icons.inventory_2_rounded;
      default:
        return null;
    }
  }

  static IconData getIconForName(String categoryName) {
    switch (categoryName.toLowerCase().trim()) {
      case 'coffee':
        return Icons.local_cafe_rounded;
      case 'pet care':
      case 'pet':
        return Icons.pets_rounded;
      case 'commute':
      case 'transport':
        return Icons.directions_car_rounded;
      case 'house repair':
      case 'repair':
        return Icons.build_rounded;
      case 'food & snacks':
      case 'food':
        return Icons.fastfood_rounded;
      case 'groceries':
        return Icons.shopping_cart_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills & utilities':
      case 'bills':
      case 'utilities':
        return Icons.bolt_rounded;
      case 'health':
        return Icons.medical_services_rounded;
      case 'other':
      default:
        return Icons.inventory_2_rounded;
    }
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final catName = json['name']?.toString() ?? 'expense';
    final rawColorHex = json['color_hex']?.toString();
    final resolvedColorHex =
        (rawColorHex == null ||
            rawColorHex.replaceAll('#', '').trim().toUpperCase() == '111111' ||
            rawColorHex.replaceAll('#', '').trim().toUpperCase() == '000000' ||
            rawColorHex.replaceAll('#', '').trim().isEmpty)
        ? getDefaultColorHexForName(catName)
        : rawColorHex;

    return CategoryModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      name: catName,
      emoji:
          json['emoji']?.toString() ??
          (json['icon_name'] != null
              ? _mapIconToEmoji(json['icon_name'].toString())
              : '📦'),
      colorHex: resolvedColorHex,
      isDefault: json['is_default'] == true,
      iconName: json['icon_name']?.toString(),
    );
  }

  static String _mapIconToEmoji(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'utensils':
      case 'food':
        return '☕';
      case 'shopping-cart':
      case 'groceries':
        return '🛒';
      case 'car':
      case 'transport':
      case 'commute':
        return '🚕';
      case 'home':
      case 'repair':
        return '🛠️';
      case 'pet':
        return '🐶';
      case 'burger':
      case 'fastfood':
        return '🍔';
      default:
        return '📦';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'emoji': emoji,
    'color_hex': colorHex,
    'is_default': isDefault,
    if (iconName != null) 'icon_name': iconName,
  };

  static List<CategoryModel> get defaultCategories => [
    CategoryModel(
      id: 'cat-coffee',
      name: 'Coffee',
      emoji: '☕',
      colorHex: '#F59E0B',
      isDefault: true,
    ),
    CategoryModel(
      id: 'cat-pet',
      name: 'Pet care',
      emoji: '🐶',
      colorHex: '#EC4899',
      isDefault: true,
    ),
    CategoryModel(
      id: 'cat-commute',
      name: 'Commute',
      emoji: '🚕',
      colorHex: '#3B82F6',
      isDefault: true,
    ),
    CategoryModel(
      id: 'cat-repair',
      name: 'House repair',
      emoji: '🛠️',
      colorHex: '#8B5CF6',
      isDefault: true,
    ),
    CategoryModel(
      id: 'cat-food',
      name: 'Food & snacks',
      emoji: '🍔',
      colorHex: '#F97316',
      isDefault: true,
    ),
    CategoryModel(
      id: 'cat-groceries',
      name: 'Groceries',
      emoji: '🛒',
      colorHex: '#10B981',
      isDefault: true,
    ),
    CategoryModel(
      id: 'cat-shopping',
      name: 'Shopping',
      emoji: '🛍️',
      colorHex: '#D946EF',
      isDefault: true,
    ),
    CategoryModel(
      id: 'cat-bills',
      name: 'Bills & utilities',
      emoji: '⚡',
      colorHex: '#EAB308',
      isDefault: true,
    ),
    CategoryModel(
      id: 'cat-health',
      name: 'Health',
      emoji: '💊',
      colorHex: '#EF4444',
      isDefault: true,
    ),
    CategoryModel(
      id: 'cat-other',
      name: 'Other',
      emoji: '📦',
      colorHex: '#06B6D4',
      isDefault: true,
    ),
  ];

  static const List<String> curatedColors = [
    '#6366F1', // Indigo
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#EF4444', // Red
    '#F97316', // Orange
    '#F59E0B', // Amber
    '#10B981', // Emerald
    '#14B8A6', // Teal
    '#3B82F6', // Blue
    '#64748B', // Slate
  ];

  static const List<CategoryIconOption> iconChoices = [
    CategoryIconOption(
      key: 'sports_esports',
      label: 'Gaming',
      icon: Icons.sports_esports_rounded,
    ),
    CategoryIconOption(
      key: 'fitness_center',
      label: 'Fitness',
      icon: Icons.fitness_center_rounded,
    ),
    CategoryIconOption(
      key: 'flight',
      label: 'Travel',
      icon: Icons.flight_takeoff_rounded,
    ),
    CategoryIconOption(
      key: 'movie',
      label: 'Entertainment',
      icon: Icons.movie_rounded,
    ),
    CategoryIconOption(
      key: 'music_note',
      label: 'Music',
      icon: Icons.music_note_rounded,
    ),
    CategoryIconOption(
      key: 'subscriptions',
      label: 'Subscriptions',
      icon: Icons.subscriptions_rounded,
    ),
    CategoryIconOption(
      key: 'school',
      label: 'Education',
      icon: Icons.school_rounded,
    ),
    CategoryIconOption(
      key: 'card_giftcard',
      label: 'Gifts',
      icon: Icons.card_giftcard_rounded,
    ),
    CategoryIconOption(
      key: 'trending_up',
      label: 'Investment',
      icon: Icons.trending_up_rounded,
    ),
    CategoryIconOption(
      key: 'savings',
      label: 'Savings',
      icon: Icons.savings_rounded,
    ),
    CategoryIconOption(key: 'work', label: 'Work', icon: Icons.work_rounded),
    CategoryIconOption(
      key: 'restaurant',
      label: 'Dining',
      icon: Icons.restaurant_rounded,
    ),
    CategoryIconOption(key: 'spa', label: 'Self Care', icon: Icons.spa_rounded),
    CategoryIconOption(
      key: 'checkroom',
      label: 'Fashion',
      icon: Icons.checkroom_rounded,
    ),
    CategoryIconOption(
      key: 'local_gas_station',
      label: 'Fuel',
      icon: Icons.local_gas_station_rounded,
    ),
    CategoryIconOption(
      key: 'two_wheeler',
      label: 'Motorbike',
      icon: Icons.two_wheeler_rounded,
    ),
    CategoryIconOption(
      key: 'wifi',
      label: 'Internet',
      icon: Icons.wifi_rounded,
    ),
    CategoryIconOption(
      key: 'palette',
      label: 'Hobby',
      icon: Icons.palette_rounded,
    ),
    CategoryIconOption(
      key: 'water_drop',
      label: 'Utilities',
      icon: Icons.water_drop_rounded,
    ),
    CategoryIconOption(key: 'book', label: 'Books', icon: Icons.book_rounded),
    CategoryIconOption(
      key: 'inventory_2',
      label: 'General',
      icon: Icons.inventory_2_rounded,
    ),
  ];
}

class CategoryIconOption {
  final String key;
  final String label;
  final IconData icon;

  const CategoryIconOption({
    required this.key,
    required this.label,
    required this.icon,
  });
}
