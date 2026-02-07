import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  late MapController _mapController;
  LatLng _currentLocation = const LatLng(40.44, -79.99); // Default to Pittsburgh
  bool _isLoadingLocation = true;
  
  // API Keys
  static const String geoapifyKey = "0df1db71ebcd4be392e29c497fe1926e";

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // Get current position
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });

        // Animate map to user location
        _mapController.move(_currentLocation, 13);

        // Start tracking location
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          if (mounted) {
            setState(() {
              _currentLocation = LatLng(position.latitude, position.longitude);
            });
          }
        });
      } else {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _onMapTap(LatLng location) async {
    // Fetch place details from Geoapify
    try {
      final url =
          'https://api.geoapify.com/v2/place-details?lat=${location.latitude}&lon=${location.longitude}&apiKey=$geoapifyKey';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final props = data['features'][0]['properties'];
          final name = props['name'] ?? 'Unknown place';
          final address = props['formatted'] ?? 'No address available';
          final categories =
              props['categories'] != null && props['categories'].isNotEmpty
                  ? (props['categories'] as List).join(', ')
                  : 'Unknown type';
          final phone = props['phone'] ?? '';
          final website = props['website'] ?? '';

          _showPlaceDetailsBottomSheet(
            name: name,
            categories: categories,
            address: address,
            phone: phone,
            website: website,
            location: location,
          );
        } else {
          _showPlaceDetailsBottomSheet(
            name: 'No place detail found',
            categories: '',
            address: 'No information available',
            phone: '',
            website: '',
            location: location,
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching place details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching place details: $e')),
      );
    }
  }

  void _showPlaceDetailsBottomSheet({
    required String name,
    required String categories,
    required String address,
    required String phone,
    required String website,
    required LatLng location,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (categories.isNotEmpty)
              Text(
                'Category: $categories',
                style: const TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 8),
            Text(
              'Address: $address',
              style: const TextStyle(color: Colors.grey),
            ),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Phone: $phone',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
            if (website.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  // You can use url_launcher package to open the website
                  debugPrint('Opening website: $website');
                },
                child: Text(
                  website,
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snap Map'),
        backgroundColor: const Color(0xFFBFE9FF), // pastel blue
      ),
      body: _isLoadingLocation
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: 13,
                onTap: (tapPosition, location) => _onMapTap(location),
              ),
              children: [
                // MapTiler vector tiles with pastel style
                TileLayer(
                  urlTemplate:
                      'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=LIrIBVdY1C3aCgd9pexM',
                  userAgentPackageName: 'com.snapmapbetter.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFC8F7D4), // pastel green
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFF2b2b2b),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mapController.move(_currentLocation, 13),
        tooltip: 'Center on current location',
        backgroundColor: const Color(0xFFBFE9FF), // pastel blue
        child: const Icon(Icons.my_location, color: Colors.black),
      ),
    );
  }
}
