import 'dart:convert';

class Product {
  const Product(this.id, this.name, this.price);

  factory Product.fromJson(Map<String, dynamic> json) =>
      Product(json['id'] as int, json['name'] as String, (json['price'] as num).toDouble());

  final int id;
  final String name;
  final double price;
}

/// A top-level function: required for `compute` / `Isolate.run`
/// (closures that capture `this` or a BuildContext cannot be sent).
List<Product> parseProducts(String body) => (jsonDecode(body) as List<dynamic>)
    .map((e) => Product.fromJson(e as Map<String, dynamic>))
    .toList(growable: false);

/// Fake large API response (~5 MB at 60k items).
String buildCatalogJson(int count) => jsonEncode([
  for (var i = 0; i < count; i++)
    {'id': i, 'name': 'Product number $i with a long descriptive name', 'price': i * 1.5},
]);
