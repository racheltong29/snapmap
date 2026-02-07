import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/photo.dart';

class PhotoService {
  final supabase = Supabase.instance.client;
  
  Future<List<Photo>> fetchPhotosAliveAt(DateTime referenceUtc) async {
    final end = referenceUtc.toUtc();
    final start = end.subtract(const Duration(hours: 168));

    final response = await supabase
        .from('photos')
        .select()
        .gt('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String())
        .order('likes', ascending: false);

    return (response as List).map((j) => Photo.fromJson(j)).toList();
  }

  // Fetch all photos (for hackathon - simple approach)
  Future<List<Photo>> fetchAllPhotos() async {
    try {
      final response = await supabase
          .from('photos')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Photo.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching photos: $e');
      return [];
    }
  }

  // Fetch photos in bounding box (for optimization later)
  Future<List<Photo>> fetchPhotosInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    try {
      final response = await supabase
          .from('photos')
          .select()
          .gte('lat', minLat)
          .lte('lat', maxLat)
          .gte('lng', minLng)
          .lte('lng', maxLng)
          .order('likes', ascending: false);

      return (response as List)
          .map((json) => Photo.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching photos in bounds: $e');
      return [];
    }
  }

  // Update photo likes
  Future<void> likePhoto(String photoId, int newLikes) async {
    try {
      await supabase
          .from('photos')
          .update({'likes': newLikes})
          .eq('id', photoId);
    } catch (e) {
      print('Error liking photo: $e');
    }
  }
}