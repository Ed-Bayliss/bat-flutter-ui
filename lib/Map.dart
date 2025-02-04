import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:burtonaletrail_app/AppApi.dart';
import 'package:burtonaletrail_app/AppColors.dart';
import 'package:burtonaletrail_app/AppDrawer.dart';
import 'package:burtonaletrail_app/AppMenuButton.dart';
import 'package:burtonaletrail_app/LoadingScreen.dart';
import 'package:burtonaletrail_app/NavBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:rive/rive.dart' as rive;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/io_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gpx/gpx.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<dynamic> markers = [];
  bool _isLoading = false;

  // GPX route points
  List<LatLng> _points = [];

  // User info (used in the greeting area)
  String userName = '';
  String userImage = '';

  // Variable to hold the current location
  LatLng? currentLocation;

  @override
  void initState() {
    super.initState();
    init();
    _loadGpxData();
  }

  Future<void> init() async {
    await _getCurrentLocation();
    _fetchMarkers();
  }

  /// Load and parse GPX data from assets
  Future<void> _loadGpxData() async {
    final points = await loadGpxFromAssets();
    setState(() {
      _points = points;
      print(_points);
    });
  }

  /// Get the current location using geolocator
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    // if (!serviceEnabled) {
    //   print('Location services are disabled.');
    //   return;
    // }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    // if (permission == LocationPermission.denied) {
    //   print('Location permissions are denied.');
    //   permission = await Geolocator.requestPermission();
    //   if (permission == LocationPermission.denied) {
    //     print(
    //         'Location permissions are permanently denied, we cannot request permissions.');
    //     return;
    //   }
    // }
    // if (permission == LocationPermission.deniedForever) {
    //   print(
    //       'Location permissions are permanently denied, we cannot request permissions.');
    //   return;
    // }

    // If permissions are granted, get the current position.
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      // For demonstration, using a hardcoded location:
      // currentLocation = LatLng(position.latitude, position.longitude);
      currentLocation = LatLng(52.828872, -1.6696312);
    });
  }

  /// Parse GPX routes (rtepts) into a list of LatLng
  List<LatLng> parseGpxToLatLng(String gpxContent) {
    final gpx = GpxReader().fromString(gpxContent);
    final List<LatLng> points = [];

    // Use the <rte> route points
    for (final track in gpx.trks) {
      for (final segment in track.trksegs) {
        for (final point in segment.trkpts) {
          final lat = point.lat;
          final lon = point.lon;
          if (lat != null && lon != null) {
            points.add(LatLng(lat, lon));
          }
        }
      }
    }
    return points;
  }

  /// Load GPX content from an asset, then parse to LatLng
  Future<List<LatLng>> loadGpxFromAssets() async {
    final gpxContent = await rootBundle.loadString('assets/Test.gpx');
    print(gpxContent);
    return parseGpxToLatLng(gpxContent);
  }

  /// Fetch marker data from the backend
  Future<void> _fetchMarkers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    bool trustSelfSigned = true;
    HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => trustSelfSigned;
    IOClient ioClient = IOClient(httpClient);

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ioClient.post(
        Uri.parse(apiServerMapInformation),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'access_token': accessToken}),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        // Assume the decoded JSON is a list of marker objects.
        if (decoded is List) {
          var allPubs = decoded;
          setState(() {
            markers = allPubs;
          });
        } else {
          throw Exception('Unexpected marker data format: Expected a list.');
        }
      } else {
        throw Exception('Failed to load marker data.');
      }
    } catch (e) {
      // Optionally log the error
      debugPrint('Marker fetch error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Helper method: if the marker image URL starts with 'http', load it from network;
  /// otherwise, load it as an asset.
  Widget buildMarkerImage(String imageUrl,
      {double width = 60, double height = 60}) {
    Widget imageWidget;

    if (imageUrl.startsWith('http')) {
      imageWidget = Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    } else {
      imageWidget = Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Image Preview'),
              content: imageUrl.startsWith('http')
                  ? Image.network(imageUrl)
                  : Image.asset(imageUrl),
              actions: <Widget>[
                TextButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          },
        );
      },
      child: ClipOval(child: imageWidget),
    );
  }

  /// Build the greeting area similar to your PubsScreen
  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Builder(
              builder: (context) {
                return AppMenuButton(
                  onTap: () => Scaffold.of(context).openDrawer(),
                );
              },
            ),
            const SizedBox(width: 10),
            const Text(
              'The Map',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () {
                // Navigate to profile screen if needed.
              },
              child: CircleAvatar(
                backgroundImage: userImage.isNotEmpty
                    ? (userImage.startsWith('http')
                        ? NetworkImage(userImage)
                        : AssetImage(userImage) as ImageProvider)
                    : null,
                child: userImage.isEmpty ? const Icon(Icons.person) : null,
              ),
            ),
            const SizedBox(width: 20),
          ],
        ),
      ],
    );
  }

  /// Build the map with markers and the GPX route as a polyline
  Widget _buildMap() {
    // Filter out markers with invalid coordinates
    final validMarkers = markers.where((markerData) {
      final lat = markerData['latitude'];
      final lng = markerData['longitude'];
      // Skip if null or invalid
      if (lat == null || lng == null) return false;
      if (lat is String && lat.toLowerCase() == 'none') return false;
      if (lng is String && lng.toLowerCase() == 'none') return false;
      return true;
    }).toList();

    // Determine the initial center of the map
    // Priority: currentLocation -> first marker -> first GPX point -> (0,0)
    LatLng? initialCenter;

    if (currentLocation != null) {
      initialCenter = currentLocation;
    } else if (validMarkers.isNotEmpty) {
      final firstMarker = validMarkers.first;
      initialCenter = LatLng(
        parseCoordinate(firstMarker['latitude']),
        parseCoordinate(firstMarker['longitude']),
      );
    } else if (_points.isNotEmpty) {
      initialCenter = _points.first;
    } else {
      initialCenter = LatLng(0, 0);
    }

    // Create a list of markers for the pub markers
    final List<Marker> mapMarkers = validMarkers.map((markerData) {
      final double latitude = parseCoordinate(markerData['latitude']);
      final double longitude = parseCoordinate(markerData['longitude']);
      final String logo = markerData['logo'] as String;
      final String name = markerData['name'] as String;

      return Marker(
        point: LatLng(latitude, longitude),
        width: 60,
        height: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildMarkerImage(logo),
            // Optionally, display a label.
            // Container(
            //   color: Colors.white.withOpacity(0.7),
            //   padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            //   child: Text(
            //     name,
            //     style: const TextStyle(fontSize: 10),
            //   ),
            // ),
          ],
        ),
      );
    }).toList();

    // Add a marker for the current location if available
    if (currentLocation != null) {
      mapMarkers.add(
        Marker(
          point: currentLocation!,
          width: 50,
          height: 50,
          child: const Icon(
            Icons.my_location,
            color: Colors.red,
            size: 30,
          ),
        ),
      );
    }

    // Build the list of layers
    final mapLayers = <Widget>[
      // 1) Base Map
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.example.app',
      ),

      // 2) GPX Route (Polyline) - if we have route points
      if (_points.isNotEmpty)
        PolylineLayer(
          polylines: [
            Polyline(
              points: _points,
              color: Colors.red, // Choose any color
              strokeWidth: 8.0,
            ),
          ],
        ),

      // 3) Markers
      MarkerLayer(markers: mapMarkers),
    ];

    // Wrap the FlutterMap in a ClipRRect to round its edges
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 600,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: initialCenter!,
            initialZoom: 14.50,
          ),
          children: mapLayers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBody: true,
      drawer: const AppDrawer(activeItem: 1),
      body: Stack(
        children: [
          // Background image and blur effects
          Positioned(
            width: size.width * 1.7,
            bottom: 100,
            left: 100,
            child: Image.asset('assets/Backgrounds/Spline.png'),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 10),
              child: Container(),
            ),
          ),
          const rive.RiveAnimation.asset('assets/RiveAssets/shapes.riv'),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 10),
              child: const SizedBox(),
            ),
          ),
          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isLoading
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGreeting(),
                        const Center(child: LoadingScreen(loadingText: "")),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGreeting(),
                        const SizedBox(height: 20),
                        _buildMap(),
                      ],
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(),
    );
  }
}

/// A helper function to parse a coordinate value safely.
double parseCoordinate(dynamic coordinate) {
  if (coordinate is String) {
    if (coordinate.toLowerCase() == 'none') {
      throw Exception('Invalid coordinate: "none"');
    }
    return double.parse(coordinate);
  }
  if (coordinate is double) return coordinate;
  if (coordinate is int) return coordinate.toDouble();
  throw Exception('Invalid coordinate type');
}

class MarkerData {
  final LatLng position;
  final String name;
  final String imageUrl;

  MarkerData({
    required this.position,
    required this.name,
    required this.imageUrl,
  });

  factory MarkerData.fromJson(Map<String, dynamic> json) {
    return MarkerData(
      position: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      name: (json['name'] ?? '') as String,
      imageUrl: json['logo'] as String,
    );
  }
}
