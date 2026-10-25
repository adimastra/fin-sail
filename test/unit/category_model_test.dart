import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fin_logs/models/category_model.dart';

void main() {
  group('CategoryModel Unit Tests', () {
    test('Default categories initialization has all 10 expected categories', () {
      final defaults = CategoryModel.defaultCategories;
      expect(defaults.length, 10);

      final names = defaults.map((c) => c.name.toLowerCase()).toSet();
      expect(names.contains('coffee'), isTrue);
      expect(names.contains('pet care'), isTrue);
      expect(names.contains('commute'), isTrue);
      expect(names.contains('house repair'), isTrue);
      expect(names.contains('food & snacks'), isTrue);
      expect(names.contains('groceries'), isTrue);
      expect(names.contains('shopping'), isTrue);
      expect(names.contains('bills & utilities'), isTrue);
      expect(names.contains('health'), isTrue);
      expect(names.contains('other'), isTrue);

      for (final cat in defaults) {
        expect(cat.isDefault, isTrue);
        expect(cat.color, isNotNull);
        expect(cat.icon, isNotNull);
      }
    });

    test('Signature color resolution works correctly for default category names', () {
      expect(CategoryModel.getDefaultColorForName('Coffee'), const Color(0xFFF59E0B));
      expect(CategoryModel.getDefaultColorForName('pet care'), const Color(0xFFEC4899));
      expect(CategoryModel.getDefaultColorForName('commute'), const Color(0xFF3B82F6));
      expect(CategoryModel.getDefaultColorForName('House Repair'), const Color(0xFF8B5CF6));
      expect(CategoryModel.getDefaultColorForName('food & snacks'), const Color(0xFFF97316));
      expect(CategoryModel.getDefaultColorForName('groceries'), const Color(0xFF10B981));
      expect(CategoryModel.getDefaultColorForName('shopping'), const Color(0xFFD946EF));
      expect(CategoryModel.getDefaultColorForName('Bills & Utilities'), const Color(0xFFEAB308));
      expect(CategoryModel.getDefaultColorForName('health'), const Color(0xFFEF4444));
      expect(CategoryModel.getDefaultColorForName('other'), const Color(0xFF06B6D4));
      expect(CategoryModel.getDefaultColorForName('unknown_custom'), const Color(0xFF06B6D4));
    });

    test('Color getter falls back to signature color when hex is invalid or #111111', () {
      final catDefaultFallback = CategoryModel(
        id: 'c1',
        name: 'Coffee',
        emoji: '☕',
        colorHex: '#111111',
      );
      expect(catDefaultFallback.color, const Color(0xFFF59E0B));

      final catCustom = CategoryModel(
        id: 'c2',
        name: 'My Special Sub',
        emoji: '⭐',
        colorHex: '#8B5CF6',
      );
      expect(catCustom.color, const Color(0xFF8B5CF6));

      final catInvalidHex = CategoryModel(
        id: 'c3',
        name: 'Shopping',
        emoji: '🛍️',
        colorHex: 'NOT_A_HEX',
      );
      expect(catInvalidHex.color, const Color(0xFFD946EF));
    });

    test('Icon resolution matches curated vector icons', () {
      final gaming = CategoryModel(
        id: 'g1',
        name: 'Gaming',
        emoji: '🎮',
        iconName: 'sports_esports',
      );
      expect(gaming.icon, Icons.sports_esports_rounded);

      final coffee = CategoryModel(
        id: 'c1',
        name: 'Coffee',
        emoji: '☕',
      );
      expect(coffee.icon, Icons.local_cafe_rounded);
    });

    test('Serialization to and from JSON preserves all fields', () {
      final original = CategoryModel(
        id: 'test-cat-1',
        userId: 'user-123',
        name: 'Subscriptions',
        emoji: '📺',
        colorHex: '#3B82F6',
        isDefault: false,
        iconName: 'subscriptions',
      );

      final json = original.toJson();
      expect(json['id'], 'test-cat-1');
      expect(json['name'], 'Subscriptions');
      expect(json['color_hex'], '#3B82F6');
      expect(json['is_default'], false);
      expect(json['icon_name'], 'subscriptions');

      final reconstructed = CategoryModel.fromJson(json);
      expect(reconstructed.id, original.id);
      expect(reconstructed.name, original.name);
      expect(reconstructed.colorHex, original.colorHex);
      expect(reconstructed.iconName, original.iconName);
      expect(reconstructed.isDefault, original.isDefault);
    });
  });
}
