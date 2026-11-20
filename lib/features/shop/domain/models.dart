import 'package:equatable/equatable.dart';

/// Money is stored in integer cents: 0.1 + 0.2 != 0.3 in floating point,
/// and a cart total must be exact.
int toCents(num value) => (value * 100).round();

String formatCents(int cents) {
  final sign = cents < 0 ? '-' : '';
  final abs = cents.abs();
  final whole = (abs ~/ 100).toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '$sign\$$whole.${(abs % 100).toString().padLeft(2, '0')}';
}

class Product extends Equatable {
  const Product({
    required this.id,
    required this.title,
    required this.priceCents,
    required this.category,
    required this.stock,
    required this.rating,
    this.thumbnail = '',
    this.discountPercent = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as int,
    title: json['title'] as String,
    priceCents: toCents(json['price'] as num),
    category: json['category'] as String? ?? '',
    stock: json['stock'] as int? ?? 0,
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    thumbnail: json['thumbnail'] as String? ?? '',
    discountPercent: (json['discountPercentage'] as num?)?.toDouble() ?? 0,
  );

  final int id;
  final String title;
  final int priceCents;
  final String category;
  final int stock;
  final double rating;
  final String thumbnail;
  final double discountPercent;

  bool get inStock => stock > 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'price': priceCents / 100,
    'category': category,
    'stock': stock,
    'rating': rating,
    'thumbnail': thumbnail,
    'discountPercentage': discountPercent,
  };

  @override
  List<Object?> get props => [id, title, priceCents, category, stock, rating, thumbnail];
}

class Category extends Equatable {
  const Category({required this.slug, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) =>
      Category(slug: json['slug'] as String, name: json['name'] as String);

  final String slug;
  final String name;

  @override
  List<Object?> get props => [slug, name];
}

class CartItem extends Equatable {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  int get totalCents => product.priceCents * quantity;

  CartItem withQuantity(int q) => CartItem(product: product, quantity: q);

  @override
  List<Object?> get props => [product, quantity];
}

enum ProductSort {
  relevance('Relevance'),
  priceLowHigh('Price: low to high'),
  priceHighLow('Price: high to low'),
  rating('Rating');

  const ProductSort(this.label);
  final String label;
}
