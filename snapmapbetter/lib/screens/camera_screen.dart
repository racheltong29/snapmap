import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../ui/ui.dart';
import '../ui/app_logos.dart';

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({super.key, required this.camera});
  final CameraDescription camera;

  @override
  State<TakePictureScreen> createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initController;

  XFile? _captured;
  bool _isUploading = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _initController = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    try {
      await _initController;
      final file = await _controller.takePicture();
      setState(() {
        _captured = file;
        _status = null;
      });
    } catch (e) {
      setState(() => _status = 'Camera error: $e');
    }
  }

  void _retake() {
    setState(() {
      _captured = null;
      _status = null;
    });
  }

  Future<Position?> _getLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.always &&
          perm != LocationPermission.whileInUse) {
        setState(() => _status = 'Location permission denied');
        return null;
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      setState(() => _status = 'Location error: $e');
      return null;
    }
  }

  Future<void> _uploadToSupabase() async {
    if (_captured == null) return;

    setState(() {
      _isUploading = true;
      _status = 'Posting…';
    });

    try {
      final pos = await _getLocation();
      if (pos == null) {
        setState(() => _isUploading = false);
        return;
      }

      final supabase = Supabase.instance.client;

      // --- Storage upload ---
      final file = File(_captured!.path);
      final ext = p.extension(file.path).isEmpty ? '.jpg' : p.extension(file.path);
      final filename = 'photo_${DateTime.now().millisecondsSinceEpoch}$ext';

      await supabase.storage.from('photos').upload(
            filename,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final publicUrl = supabase.storage.from('photos').getPublicUrl(filename);

      // --- DB insert ---
      await supabase.from('photos').insert({
        'image_url': publicUrl,
        'lat': pos.latitude,
        'lng': pos.longitude,
        'likes': 0,
      });

      setState(() {
        _status = 'Posted to map ✅';
        _isUploading = false;
        _captured = null;
      });
    } catch (e) {
      setState(() {
        _status = 'Upload failed: $e';
        _isUploading = false;
      });
    }
  }

  Future<void> _flipCamera() async {
    // Optional: implement if you have multiple cameras.
    setState(() => _status = 'Flip not wired yet (optional).');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _initController,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final preview = _captured == null
                ? CameraPreview(_controller)
                : Image.file(File(_captured!.path), fit: BoxFit.cover);

            return Stack(
              children: [
                Positioned.fill(child: preview),

                // Top scrim
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: GradientScrim(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    height: 160,
                  ),
                ),

                // Bottom scrim
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: GradientScrim(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    height: 220,
                  ),
                ),

                // Top bar (Stories-like)
                Positioned(
                  left: 16,
                  right: 16,
                  top: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            // ✅ ONLY this logo is swapped to your SVG icon variant
                            const SnapMapTitleIcon(size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'SnapMap',
                              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 220.ms).slideY(begin: -0.2, end: 0),

                      Row(
                        children: [
                          _topIconButton(
                            icon: Icons.flip_camera_ios_rounded,
                            onTap: _flipCamera,
                          ),
                          const SizedBox(width: 10),
                          _topIconButton(
                            icon: Icons.close_rounded,
                            onTap: () {
                              if (_captured != null) _retake();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status toast
                if (_status != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    top: 76,
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          if (_isUploading)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            const Icon(Icons.info_outline, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _status!,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 180.ms).slideY(begin: -0.15, end: 0),
                  ),

                // Bottom controls (Stories-style)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 18,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Action row (retake / post)
                      if (_captured != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: GlassCard(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: Center(
                                    child: Text(
                                      'Retake',
                                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: PillButton(
                                  onTap: _isUploading ? () {} : _uploadToSupabase,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.send_rounded, size: 18),
                                      const SizedBox(width: 8),
                                      Text(_isUploading ? 'Posting…' : 'Post'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(duration: 180.ms).slideY(begin: 0.12, end: 0),
                        ),

                      const SizedBox(height: 14),

                      // Shutter row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GlassCard(
                              padding: const EdgeInsets.all(10),
                              child: const Icon(Icons.flash_off_rounded, size: 20),
                            ),

                            GestureDetector(
                              onTap: (_captured == null && !_isUploading) ? _capture : null,
                              child: StoryRing(
                                size: 74,
                                child: Container(
                                  color: AppTheme.bg,
                                  child: Center(
                                    child: Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _captured == null ? Colors.white : AppTheme.surface2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(duration: 220.ms).scale(
                                  begin: const Offset(0.98, 0.98),
                                  end: const Offset(1, 1),
                                ),

                            GlassCard(
                              padding: const EdgeInsets.all(10),
                              child: const Icon(Icons.tune_rounded, size: 20),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),
                      Text(
                        _captured == null ? 'Tap to capture' : 'Preview',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: AppTheme.text.withOpacity(0.85),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _topIconButton({required IconData icon, required VoidCallback onTap}) {
    return GlassCard(
      padding: const EdgeInsets.all(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Icon(icon, size: 20, color: AppTheme.text),
      ),
    );
  }
}
