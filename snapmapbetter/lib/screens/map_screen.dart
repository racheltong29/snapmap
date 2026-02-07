import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../widgets/time_travel_panel.dart';
import '../config/config.dart';
import '../models/photo.dart';
import '../services/photo_service.dart';
import '../widgets/photo_stack_viewer.dart';
import '../ui/frosted_glass.dart';
import '../ui/app_logos.dart';

const kSlate = Color(0xFF2F3A40); // dark slate gray
const kBorder = Colors.white; // white outline

// Lighter glass tuning (so it’s not dark/grey)
const _glassFill = Color.fromRGBO(255, 255, 255, 0.16);
const _glassFillStrong = Color.fromRGBO(255, 255, 255, 0.24);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  late final MapController _mapController;
  final PhotoService _photoService = PhotoService();

  bool _timeTravelEnabled = false;
  DateTime _timeCursorUtc = DateTime.now().toUtc();
  TimeUnit _unit = TimeUnit.hours;

  LatLng _currentLocation = const LatLng(40.44, -79.99);
  bool _isLoadingLocation = true;

  List<Photo> _photos = [];
  bool _isLoadingPhotos = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeLocation();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoadingPhotos = true);

    final ref = _timeTravelEnabled ? _timeCursorUtc : DateTime.now().toUtc();
    final photos = await _photoService.fetchPhotosAliveAt(ref);

    if (!mounted) return;
    setState(() {
      _photos = photos;
      _isLoadingPhotos = false;
    });
  }

  Future<void> _initializeLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        if (!mounted) return;
        setState(() {
          _currentLocation = LatLng(pos.latitude, pos.longitude);
          _isLoadingLocation = false;
        });

        _mapController.move(_currentLocation, 13);

        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((pos) {
          if (!mounted) return;
          setState(() {
            _currentLocation = LatLng(pos.latitude, pos.longitude);
          });
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoadingLocation = false);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (!mounted) return;
      setState(() => _isLoadingLocation = false);
    }
  }

  // ---------- MARKERS ----------

  List<Marker> _buildPhotoMarkers() {
    return _photos.map((photo) {
      return Marker(
        point: photo.location,
        width: 50,
        height: 50,
        child: GestureDetector(
          onTap: () => _onPhotoMarkerTap(photo.location),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kBorder, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                photo.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: const Color(0xFF0B0D10),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF0B0D10),
                    alignment: Alignment.center,
                    child: const Icon(Icons.photo, color: Colors.white, size: 22),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  void _onPhotoMarkerTap(LatLng location) {
    final nearbyPhotos = _photos.where((photo) {
      final distance = const Distance().as(
        LengthUnit.Meter,
        location,
        photo.location,
      );
      return distance < 500;
    }).toList();

    nearbyPhotos.sort((a, b) => b.likes.compareTo(a.likes));

    if (nearbyPhotos.isNotEmpty) {
      _showPhotoStack(nearbyPhotos);
    }
  }

  void _showPhotoStack(List<Photo> photos) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => PhotoStackViewer(photos: photos),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: _isLoadingLocation
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation,
                    initialZoom: 13,
                    maxZoom: 18,
                    minZoom: 3,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=${ApiConfig.maptilerKey}',
                      userAgentPackageName: 'com.snapmapbetter.app',
                    ),

                    // CLUSTERS
                    if (!_isLoadingPhotos && _photos.isNotEmpty)
                      MarkerClusterLayerWidget(
                        options: MarkerClusterLayerOptions(
                          maxClusterRadius: 80,
                          size: const Size(60, 60),
                          markers: _buildPhotoMarkers(),
                          builder: (context, markers) {
                            return _buildClusterMarker(markers.length, markers);
                          },
                          onClusterTap: (cluster) {
                            final clusterPhotos = cluster.markers.map((marker) {
                              return _photos.firstWhere(
                                (photo) => photo.location == marker.point,
                              );
                            }).toList();

                            clusterPhotos.sort((a, b) => b.likes.compareTo(a.likes));
                            _showPhotoStack(clusterPhotos);
                          },
                        ),
                      ),

                    // CURRENT LOCATION MARKER (square plate + circular dot)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLocation,
                          width: 35,
                          height: 35,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 33,
                                height: 33,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Colors.black.withOpacity(0.25),
                                  border: Border.all(color: kBorder, width: 1.5),
                                ),
                              ),
                              Container(
                                width: 25,
                                height: 25,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.10),
                                ),
                              ),
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.92),
                                  border: Border.all(color: kBorder, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.35),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // TOP FROSTED BAR (lighter)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: FrostedGlass(
                            radius: 22,
                            blur: 30,
                            borderColor: kBorder,
                            borderWidth: 1.6,
                            fillColor: _glassFill,
                            gradientOpacity: 0.90,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  'Snap Map',
                                  style: TextStyle(
                                    color: kSlate,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),

                                // ✅ only this icon becomes SVG
                                SnapMapTitleIcon(size: 18),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // ✅ keep refresh as Material icon
                        FrostedGlass(
                          radius: 22,
                          blur: 30,
                          borderColor: kBorder,
                          borderWidth: 1.6,
                          fillColor: _glassFill,
                          gradientOpacity: 0.90,
                          padding: const EdgeInsets.all(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: _loadPhotos,
                            child: const Icon(Icons.refresh, color: kSlate),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // TIME TRAVEL BUTTON (higher + lighter glass) ✅ keep Material icon
                Positioned(
                  right: 14,
                  bottom: 260,
                  child: FrostedGlass(
                    radius: 22,
                    blur: 30,
                    borderColor: kBorder,
                    borderWidth: 1.6,
                    fillColor: _glassFill,
                    gradientOpacity: 0.90,
                    padding: const EdgeInsets.all(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        setState(() {
                          _timeTravelEnabled = !_timeTravelEnabled;
                          _timeCursorUtc = DateTime.now().toUtc();
                        });
                        _loadPhotos();
                      },
                      child: Icon(
                        _timeTravelEnabled ? Icons.schedule : Icons.schedule_outlined,
                        color: kSlate,
                      ),
                    ),
                  ),
                ),

                // TIME TRAVEL PANEL
                if (_timeTravelEnabled)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 86,
                    child: TimeTravelPanel(
                      cursorUtc: _timeCursorUtc,
                      unit: _unit,
                      onUnitChanged: (u) {
                        setState(() => _unit = u);
                        _loadPhotos();
                      },
                      onCursorChanged: (t) {
                        setState(() => _timeCursorUtc = t);
                        _loadPhotos();
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  // ---------- CLUSTER MARKER ----------

  Widget _buildClusterMarker(int count, List<Marker> markers) {
    Photo? topPhoto;
    if (markers.isNotEmpty) {
      try {
        topPhoto = _photos.firstWhere(
          (p) => p.location == markers.first.point,
        );
      } catch (_) {}
    }

    return Stack(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: kBorder, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.30),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipOval(
            child: topPhoto == null
                ? Container(color: const Color(0xFF0B0D10))
                : Image.network(
                    topPhoto.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: const Color(0xFF0B0D10));
                    },
                  ),
          ),
        ),

        Positioned(
          bottom: 0,
          right: 0,
          child: FrostedGlass(
            radius: 14,
            blur: 24,
            borderColor: kBorder,
            borderWidth: 1.4,
            fillColor: _glassFillStrong,
            gradientOpacity: 0.95,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              '$count',
              style: const TextStyle(
                color: kSlate,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
