import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_market/models/product_model.dart';
import 'package:uni_market/widgets/product_card.dart';
import 'package:uni_market/utils/currency_formatter.dart';

void main() {
  final testProductNormal = ProductModel(
    productId: 'test_1',
    sellerId: 'seller_1',
    title: 'Normal Title',
    description: 'This is a normal product description.',
    price: 99.99,
    category: 'Electronics',
    condition: 'Like New',
    imageUrls: ['https://example.com/image.jpg'],
    createdAt: DateTime.now(),
    stockQuantity: 1,
    location: 'Main Campus Library',
    sellerName: 'John Doe',
    sellerRating: 4.8,
  );

  final testProductLong = ProductModel(
    productId: 'test_2',
    sellerId: 'seller_1',
    title: 'Very Long Title That Spans Multiple Lines If Not Constrained Properly and Should Ellipsis',
    description: 'This is a normal product description.',
    price: 1249.99,
    category: 'Fashion & Apparel',
    condition: 'Good',
    imageUrls: ['https://example.com/image.jpg'],
    createdAt: DateTime.now(),
    stockQuantity: 1,
    location: 'Very Long Location Name That Might Also Cause Overflow In Row',
    sellerName: 'Jane Smith',
    sellerRating: 4.5,
  );

  Widget buildTestableWidget(ProductModel product, {required double width, required double height}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: ProductCard(
              product: product,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('ProductCard does not overflow on standard size with normal text', (WidgetTester tester) async {
    // Standard card size in grid: ~158 width, ~220 height
    await tester.pumpWidget(buildTestableWidget(testProductNormal, width: 158, height: 220));
    expect(find.byType(ProductCard), findsOneWidget);
    // Ensure no layout overflow exception is thrown
    expect(tester.takeException(), isNull);
  });

  testWidgets('ProductCard does not overflow on small screen / small card size with long text', (WidgetTester tester) async {
    // Small screen card size: ~140 width, ~190 height
    await tester.pumpWidget(buildTestableWidget(testProductLong, width: 140, height: 190));
    expect(find.byType(ProductCard), findsOneWidget);
    // Ensure no layout overflow exception is thrown
    expect(tester.takeException(), isNull);
  });

  testWidgets('ProductCard does not overflow on very narrow width (e.g. 120) with long text', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(testProductLong, width: 120, height: 170));
    expect(find.byType(ProductCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('CurrencyFormatter tests', () {
    test('formats prices with Bangladeshi Taka symbol and thousands separator', () {
      expect(CurrencyFormatter.format(250), '৳250');
      expect(CurrencyFormatter.format(1000), '৳1,000');
      expect(CurrencyFormatter.format(12500), '৳12,500');
      expect(CurrencyFormatter.format(99.99), '৳100'); // rounded to nearest int
      expect(CurrencyFormatter.format(1249.99), '৳1,250'); // rounded and separated
    });
  });
}
