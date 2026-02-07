import 'package:latlong2/latlong.dart';

class Photo {
  final String id;
  final String imageUrl;
  final double lat;
  final double lng;
  final int likes;
  final DateTime createdAt;

  Photo({
    required this.id,
    required this.imageUrl,
    required this.lat,
    required this.lng,
    required this.likes,
    required this.createdAt,
  });

  LatLng get location => LatLng(lat, lng);

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      imageUrl: json['image_url'],
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      likes: json['likes'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}