import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/app_theme.dart';
import 'screens/map_screen.dart';
import 'screens/camera_screen.dart';
import 'widgets/drag_mode_slider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch async errors so you SEE them instead of hanging forever.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  runApp(const SnapMapApp());
}

class SnapMapApp extends StatelessWidget {
  const SnapMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const InitGate(),
    );
  }
}

/// Initializes Supabase + Camera AFTER UI is up.
/// If anything fails, user sees an error screen instead of a stuck logo.
class InitGate extends StatefulWidget {
  const InitGate({super.key});

  @override
  State<InitGate> createState() => _InitGateState();
}

class _InitGateState extends State<InitGate> {
  late Future<CameraDescription> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _init();
  }

  Future<CameraDescription> _init() async {
    const supabaseUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://mqumfmhzwcetnkdkllpj.supabase.co',
    );
    const supabaseAnonKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1xdW1mbWh6d2NldG5rZGtsbHBqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA0MjEwMjYsImV4cCI6MjA4NTk5NzAyNn0.8O5XYtDEYJMWmU5TktyTAVfj9aadWxJQ9PMI26XSXgQ',
    );

    // 1) Supabase
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

    // 2) Camera (this can throw on emulators/no permission)
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No cameras found on this device.');
    }
    return cameras.first;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CameraDescription>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingScreen();
        }

        if (snapshot.hasError) {
          return _ErrorScreen(
            error: snapshot.error.toString(),
            onRetry: () => setState(() => _initFuture = _init()),
          );
        }

        return MainNavigationScreen(camera: snapshot.data!);
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text(
              'Loading SnapMap…',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorScreen({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 44),
              const SizedBox(height: 10),
              const Text(
                'Startup failed',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                error,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Main navigation screen that handles camera and map tabs
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key, required this.camera});

  final CameraDescription camera;

  @override
  MainNavigationScreenState createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    TakePictureScreen(camera: widget.camera),
    const MapScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: DragModeSlider(
            index: _selectedIndex,
            onChanged: (i) => setState(() => _selectedIndex = i),
          ),
        ),
      ),
    );
  }
}
