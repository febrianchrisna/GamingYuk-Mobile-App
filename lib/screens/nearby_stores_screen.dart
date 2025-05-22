import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:toko_game/utils/constants.dart';
import 'package:toko_game/widgets/custom_button.dart';

// Define GameStore class at file level, not inside another class
class GameStore {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final bool isOpen;
  final double? distance;

  GameStore({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.isOpen,
    this.distance,
  });

  GameStore copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    double? rating,
    bool? isOpen,
    double? distance,
  }) {
    return GameStore(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      isOpen: isOpen ?? this.isOpen,
      distance: distance ?? this.distance,
    );
  }
}

class NearbyStoresScreen extends StatefulWidget {
  const NearbyStoresScreen({super.key});

  @override
  State<NearbyStoresScreen> createState() => _NearbyStoresScreenState();
}

class _NearbyStoresScreenState extends State<NearbyStoresScreen> {
  Position? _currentPosition;
  bool _isLoading = true;
  String? _errorMessage;
  final MapController _mapController = MapController();

  // TomTom API key
  final String _tomtomApiKey = 'bDmTXFtHAVG0ucnGY9NC2sfCfAAafYtC';

  List<GameStore> _nearbyStores = [];
  GameStore? _selectedStore;
  bool _isMapInitialized = false;

  // Route-related state variables
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  bool _showingDirections = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _moveMapToLocation(LatLng location, double zoom) {
    // Only attempt to move the map if the widget is mounted and the map is initialized
    if (_isMapInitialized) {
      try {
        _mapController.move(location, zoom);
      } catch (e) {
        print('Error moving map: $e');
      }
    }
  }

  void _selectStore(GameStore store) {
    setState(() {
      _selectedStore = store;
    });

    _moveMapToLocation(LatLng(store.latitude, store.longitude), 14.0);
  }

  void _calculateDistancesForSampleData(Position position) {
    // Fallback sample data in case API fails
    final sampleStores = [
      GameStore(
        id: '1',
        name: 'GameStop',
        address: '123 Main St, Jakarta',
        latitude: -6.2088,
        longitude: 106.8456,
        rating: 4.5,
        isOpen: true,
      ),
      GameStore(
        id: '2',
        name: 'Game World',
        address: '456 Oak St, Jakarta',
        latitude: -6.2000,
        longitude: 106.8300,
        rating: 4.2,
        isOpen: true,
      ),
      GameStore(
        id: '3',
        name: 'Digital Games',
        address: '789 Pine St, Jakarta',
        latitude: -6.1900,
        longitude: 106.8200,
        rating: 3.8,
        isOpen: false,
      ),
      GameStore(
        id: '4',
        name: 'Console Heaven',
        address: '101 Maple Ave, Jakarta',
        latitude: -6.2200,
        longitude: 106.8500,
        rating: 4.7,
        isOpen: true,
      ),
      GameStore(
        id: '5',
        name: 'Retro Gaming',
        address: '202 Elm St, Jakarta',
        latitude: -6.2300,
        longitude: 106.8350,
        rating: 4.0,
        isOpen: true,
      ),
    ];

    final storesWithDistance = sampleStores.map((store) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        store.latitude,
        store.longitude,
      );
      return store.copyWith(distance: distance);
    }).toList();

    storesWithDistance.sort((a, b) => (a.distance ?? double.infinity)
        .compareTo(b.distance ?? double.infinity));

    setState(() {
      _nearbyStores = storesWithDistance;

      // Select the first store by default
      if (storesWithDistance.isNotEmpty) {
        _selectedStore = storesWithDistance.first;
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      // Search for nearby game stores using TomTom API
      await _searchNearbyGameStores(position);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _searchNearbyGameStores(Position position) async {
    try {
      // Build TomTom Nearby Search API URL
      final url = 'https://api.tomtom.com/search/2/search/video game store.json'
          '?key=$_tomtomApiKey'
          '&lat=${position.latitude}'
          '&lon=${position.longitude}'
          '&radius=10000'
          '&limit=20';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        if (results.isEmpty) {
          // If no results from TomTom, fallback to sample data
          _calculateDistancesForSampleData(position);
          return;
        }

        // Parse the results
        final stores = results.map((result) {
          final position = result['position'];
          final address = result['address'];
          final poi = result['poi'];

          // Generate a unique ID if not available
          final id = result['id'] ?? '${position['lat']}-${position['lon']}';

          // Calculate distance
          final distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            position['lat'],
            position['lon'],
          );

          return GameStore(
            id: id.toString(),
            name: poi['name'],
            address: address['freeformAddress'] ?? 'Unknown address',
            latitude: position['lat'],
            longitude: position['lon'],
            rating: poi['categories'] != null && poi['categories'].isNotEmpty
                ? 4.0
                : 3.5, // TomTom doesn't provide ratings, so use a default
            isOpen:
                true, // TomTom doesn't provide opening hours in the basic API
            distance: distance,
          );
        }).toList();

        // Sort by distance
        stores.sort((a, b) => (a.distance ?? double.infinity)
            .compareTo(b.distance ?? double.infinity));

        setState(() {
          _nearbyStores = stores;

          // Select the first store by default
          if (stores.isNotEmpty) {
            _selectedStore = stores.first;

            // Center the map on the first store
            _moveMapToLocation(
                LatLng(stores.first.latitude, stores.first.longitude), 13.0);
          }
        });
      } else {
        throw Exception('Failed to load nearby stores: ${response.statusCode}');
      }
    } catch (e) {
      print('TomTom API error: $e');
      // If TomTom API fails, fall back to sample data with actual distances
      _calculateDistancesForSampleData(position);
    }
  }

  // Improved directions method
  Future<void> _showDirections(GameStore store) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to determine your location'),
        ),
      );
      return;
    }

    setState(() {
      _isLoadingRoute = true;
      _showingDirections = true;
    });

    try {
      // Fix coordinate format - TomTom expects latitude,longitude (not longitude,latitude)
      final origin =
          '${_currentPosition!.latitude},${_currentPosition!.longitude}';
      final destination = '${store.latitude},${store.longitude}';

      // Log the coordinates for debugging
      print('Origin coordinates: $origin');
      print('Destination coordinates: $destination');

      // Fix the API URL format to match TomTom's requirements
      final url =
          'https://api.tomtom.com/routing/1/calculateRoute/$origin:$destination/json'
          '?key=$_tomtomApiKey'
          '&travelMode=pedestrian'
          '&routeType=fastest';

      print('Requesting directions from: $url');
      final response = await http.get(Uri.parse(url));
      print('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Route data received: ${data.keys}');

        if (data.containsKey('routes') && data['routes'].isNotEmpty) {
          final routes = data['routes'] as List;
          final route = routes.first;

          if (route.containsKey('legs') && route['legs'].isNotEmpty) {
            final legs = route['legs'] as List;
            final leg = legs.first;

            final List<LatLng> routePoints = [];

            // Extract route points from the response
            if (leg.containsKey('points') && leg['points'].isNotEmpty) {
              // Handle 'points' format if present
              final List points = leg['points'];
              routePoints.addAll(points.map((point) {
                return LatLng(point['latitude'], point['longitude']);
              }));
            } else if (route.containsKey('legs') &&
                route['legs'].isNotEmpty &&
                route['legs'][0].containsKey('points')) {
              // Alternative access method
              final List points = route['legs'][0]['points'];
              routePoints.addAll(points.map((point) {
                return LatLng(point['latitude'], point['longitude']);
              }));
            } else {
              // Try to extract coordinates from the 'geometry' property if points not found
              if (route.containsKey('geometry')) {
                final String geometry = route['geometry'];
                // Parse the geometry format (usually polyline encoded)
                try {
                  // Simple approach: if it's a JSON string, try to parse it
                  final List<dynamic> coordinates = json.decode(geometry);
                  for (var coord in coordinates) {
                    if (coord is List && coord.length >= 2) {
                      routePoints.add(LatLng(coord[0], coord[1]));
                    }
                  }
                } catch (e) {
                  print('Could not parse geometry: $e');
                }
              }
            }

            if (routePoints.isNotEmpty) {
              setState(() {
                _routePoints = routePoints;
                _isLoadingRoute = false;
              });

              // Fit map to show the entire route with padding
              final bounds = LatLngBounds.fromPoints(routePoints);
              _mapController.fitCamera(
                CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(50.0),
                ),
              );
              return;
            } else {
              throw Exception('No route points found in the response');
            }
          }
        }

        throw Exception('No route found in the response data');
      } else {
        // Print response body for debugging
        print('Error response body: ${response.body}');
        throw Exception('Failed to get directions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting directions: $e');
      setState(() {
        _isLoadingRoute = false;
        _showingDirections = false;
        _routePoints = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not calculate directions: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _clearDirections() {
    setState(() {
      _routePoints = [];
      _showingDirections = false;
    });

    // Center back on the selected store
    if (_selectedStore != null) {
      _moveMapToLocation(
          LatLng(_selectedStore!.latitude, _selectedStore!.longitude), 14.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Game Stores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_off,
                          size: 60,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: $_errorMessage',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: 'Try Again',
                          onPressed: _getCurrentLocation,
                          icon: Icons.refresh,
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Map view
                    Expanded(
                      flex: 3,
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _currentPosition != null
                                  ? LatLng(
                                      _currentPosition!.latitude,
                                      _currentPosition!.longitude,
                                    )
                                  : const LatLng(
                                      -6.2088, 106.8456), // Default to Jakarta
                              initialZoom: 13.0,
                              onTap: (tapPosition, latLng) {
                                setState(() {
                                  _selectedStore = null;
                                });
                              },
                              onMapReady: () {
                                setState(() {
                                  _isMapInitialized = true;
                                });
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                subdomains: const ['a', 'b', 'c'],
                                userAgentPackageName: 'com.example.app',
                              ),
                              // Add PolylineLayer for showing directions
                              if (_routePoints.isNotEmpty)
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: _routePoints,
                                      strokeWidth: 4.0,
                                      color: Colors.blue,
                                    ),
                                  ],
                                ),
                              MarkerLayer(
                                markers: [
                                  // Current location marker
                                  if (_currentPosition != null)
                                    Marker(
                                      width: 40.0,
                                      height: 40.0,
                                      point: LatLng(
                                        _currentPosition!.latitude,
                                        _currentPosition!.longitude,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withAlpha(179),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.person_pin_circle,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),

                                  // Game store markers
                                  ..._nearbyStores.map((store) {
                                    return Marker(
                                      width: 50.0,
                                      height: 50.0,
                                      point: LatLng(
                                        store.latitude,
                                        store.longitude,
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedStore = store;
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: _selectedStore?.id ==
                                                    store.id
                                                ? Colors.red.withAlpha(230)
                                                : Colors.white.withAlpha(230),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    Colors.black.withAlpha(51),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.videogame_asset,
                                            color:
                                                _selectedStore?.id == store.id
                                                    ? Colors.white
                                                    : store.isOpen
                                                        ? Colors.green
                                                        : Colors.grey,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),

                          // Show loading indicator when calculating route
                          if (_isLoadingRoute)
                            const Center(
                              child: Card(
                                color: Colors.white,
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 8),
                                      Text('Calculating route...'),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // Selected store info
                          if (_selectedStore != null)
                            Positioned(
                              bottom: 16,
                              left: 16,
                              right: 16,
                              child: Card(
                                elevation: 4,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _selectedStore!.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _selectedStore!.address,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _selectedStore!.isOpen
                                                  ? Colors.green[50]
                                                  : Colors.red[50],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              _selectedStore!.isOpen
                                                  ? 'Open'
                                                  : 'Closed',
                                              style: TextStyle(
                                                color: _selectedStore!.isOpen
                                                    ? Colors.green
                                                    : Colors.red,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Row(
                                            children: List.generate(5, (index) {
                                              return Icon(
                                                index <
                                                        _selectedStore!.rating
                                                            .floor()
                                                    ? Icons.star
                                                    : index <
                                                            _selectedStore!
                                                                .rating
                                                        ? Icons.star_half
                                                        : Icons.star_border,
                                                color: Colors.amber,
                                                size: 16,
                                              );
                                            }),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${_selectedStore!.rating}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '${(_selectedStore!.distance! / 1000).toStringAsFixed(2)} km',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: _showingDirections
                                            ? ElevatedButton.icon(
                                                onPressed: _clearDirections,
                                                icon: const Icon(Icons.close),
                                                label: const Text(
                                                    'Clear Directions'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  foregroundColor: Colors.white,
                                                ),
                                              )
                                            : ElevatedButton.icon(
                                                onPressed: () =>
                                                    _showDirections(
                                                        _selectedStore!),
                                                icon: const Icon(
                                                    Icons.directions),
                                                label: const Text(
                                                    'Show Directions'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.primaryColor,
                                                  foregroundColor: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Store list
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(26),
                              blurRadius: 6,
                              offset: const Offset(0, -3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.store,
                                    size: 20,
                                    color: AppColors.primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Nearby Game Stores',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.primaryColor.withAlpha(26),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '${_nearbyStores.length} found',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: _nearbyStores.length,
                                itemBuilder: (context, index) {
                                  final store = _nearbyStores[index];
                                  return ListTile(
                                    selected: _selectedStore?.id == store.id,
                                    selectedTileColor:
                                        AppColors.primaryColor.withAlpha(26),
                                    onTap: () => _selectStore(store),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: store.isOpen
                                            ? Colors.green[50]
                                            : Colors.red[50],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.videogame_asset,
                                        color: store.isOpen
                                            ? Colors.green
                                            : Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      store.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      store.address,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Text(
                                      '${(store.distance! / 1000).toStringAsFixed(2)} km',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
