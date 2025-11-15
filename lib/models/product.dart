class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String unit;
  final String category;
  final int stockQuantity;
  final int minStockLevel;
  final DateTime dateAdded;

  Product({
    String? id,
    required this.name,
    required this.description,
    required this.price,
    required this.unit,
    required this.category,
    required this.stockQuantity,
    required this.minStockLevel,
    DateTime? dateAdded,
  }) : id = id ?? '',
       dateAdded = dateAdded ?? DateTime.now();

  // Legacy compatibility getters
  double get pricePerUnit => price;
  int get availableQuantity => stockQuantity;

  // Convert from Supabase data
  factory Product.fromSupabase(Map<String, dynamic> data) {
    return Product(
      id: data['id'],
      name: data['name'],
      description: data['description'] ?? '',
      price: (data['price'] as num).toDouble(),
      unit: data['unit'],
      category: data['category'],
      stockQuantity: data['stock_quantity'],
      minStockLevel: data['min_stock_level'],
      dateAdded: DateTime.parse(data['created_at']),
    );
  }

  // Convert to Supabase data
  Map<String, dynamic> toSupabase({bool includeId = false}) {
    final data = {
      'name': name,
      'description': description,
      'price': price,
      'unit': unit,
      'category': category,
      'stock_quantity': stockQuantity,
      'min_stock_level': minStockLevel,
    };
    if (includeId && id.isNotEmpty) {
      data['id'] = id;
    }
    return data;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'unit': unit,
      'category': category,
      'stockQuantity': stockQuantity,
      'minStockLevel': minStockLevel,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: json['price']?.toDouble() ?? json['pricePerUnit']?.toDouble() ?? 0.0,
      unit: json['unit'] ?? 'Unit',
      category: json['category'] ?? 'General',
      stockQuantity: json['stockQuantity'] ?? json['availableQuantity'] ?? 0,
      minStockLevel: json['minStockLevel'] ?? 0,
      dateAdded: json['dateAdded'] != null ? DateTime.parse(json['dateAdded']) : DateTime.now(),
    );
  }
}
