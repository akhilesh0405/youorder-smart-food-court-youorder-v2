class Restaurant {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String location;
  final double rating;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.location,
    this.rating = 0.0,
  });

  factory Restaurant.fromFirestore(Map<String, dynamic> data, String id) {
    return Restaurant(
      id: id,
      name: data['name'] ?? 'Unknown Restaurant',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      location: data['location'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
    );
  }
}