class MenuItem {
  final String id;
  final String restaurantId;
  final String name;
  final double price;
  final String description;
  final String category;
  final String imageUrl;
  final bool isAvailable;

  MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
    this.isAvailable = true,
  });

  factory MenuItem.fromFirestore(Map<String, dynamic> data, String id) {
    return MenuItem(
      id: id,
      restaurantId: data['restaurantId'] ?? '',
      name: data['name'] ?? 'Unknown Item',
      price: (data['price'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
    );
  }
}